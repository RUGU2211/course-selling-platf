package com.example.payment.service;

import com.example.payment.dto.CreateOrderRequest;
import com.example.payment.dto.CreateOrderResponse;
import com.example.payment.dto.VerifyPaymentRequest;
import com.example.payment.entity.AppOrder;
import com.example.payment.entity.Payment;
import com.example.payment.repository.OrderRepository;
import com.example.payment.repository.PaymentRepository;
import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Formatter;
import java.util.List;

@Service
public class PaymentService {

    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;
    private final RazorpayClient razorpayClient;

    @Value("${razorpay.key.id}")
    private String razorpayKeyId;

    @Value("${razorpay.key.secret}")
    private String razorpaySecret;

    public PaymentService(OrderRepository orderRepository,
                          PaymentRepository paymentRepository,
                          @Value("${razorpay.key.id}") String keyId,
                          @Value("${razorpay.key.secret}") String secret) throws Exception {
        this.orderRepository = orderRepository;
        this.paymentRepository = paymentRepository;
        this.razorpayClient = new RazorpayClient(keyId, secret);
    }

    /** Step 1: Create Razorpay order and save in DB */
    @Transactional
    public CreateOrderResponse createOrder(CreateOrderRequest req) throws Exception {
        int amountInPaise = (int) (req.getAmount() * 100);

        JSONObject options = new JSONObject();
        options.put("amount", amountInPaise);
        options.put("currency", "INR");
        options.put("payment_capture", 1);

        Order razorpayOrder = razorpayClient.orders.create(options);

        AppOrder order = new AppOrder();
        order.setUserId(req.getUserId());
        order.setCourseId(req.getCourseId());
        order.setAmount(req.getAmount());
        order.setStatus("CREATED");
        order.setExternalOrderId(razorpayOrder.get("id"));
        order.setCreatedAt(LocalDateTime.now());

        AppOrder savedOrder = orderRepository.save(order);

        return new CreateOrderResponse(
                razorpayOrder.get("id"),
                razorpayKeyId,
                req.getAmount(),
                "INR",
                savedOrder.getId()
        );
    }

    /** Step 2: Verify payment signature and record payment */
    @Transactional
    public void verifyPayment(VerifyPaymentRequest req) throws Exception {
        String payload = req.getRazorpayOrderId() + "|" + req.getRazorpayPaymentId();
        String generatedSignature = generateSignature(payload, razorpaySecret);

        if (!generatedSignature.equals(req.getRazorpaySignature())) {
            throw new IllegalArgumentException("Invalid payment signature");
        }

        AppOrder order = orderRepository.findByExternalOrderId(req.getRazorpayOrderId())
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));

        order.setStatus("PAID");
        orderRepository.save(order);

        Payment payment = new Payment();
        payment.setAppOrderId(order.getId());
        payment.setPaymentRef(req.getRazorpayPaymentId());
        payment.setMethod("RAZORPAY");
        payment.setStatus("SUCCESS");
        payment.setCreatedAt(LocalDateTime.now());

        paymentRepository.save(payment);
    }

    /** Step 3: Refund order (dummy implementation) */
    @Transactional
    public AppOrder refundOrder(Long orderId) {
        AppOrder order = orderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("Order not found"));
        order.setStatus("REFUNDED");
        return orderRepository.save(order);
    }

    /** Step 4: Get all orders by user */
    public List<AppOrder> getOrdersByUser(Long userId) {
        return orderRepository.findByUserId(userId);
    }

    /** Utility: HMAC-SHA256 signature (HEX) */
    private String generateSignature(String data, String secret) throws Exception {
        Mac sha256Hmac = Mac.getInstance("HmacSHA256");
        SecretKeySpec keySpec = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        sha256Hmac.init(keySpec);
        byte[] hash = sha256Hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));

        Formatter formatter = new Formatter();
        for (byte b : hash) formatter.format("%02x", b);
        String hex = formatter.toString();
        formatter.close();
        return hex;
    }
}
