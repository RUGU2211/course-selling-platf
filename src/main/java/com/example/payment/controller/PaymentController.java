package com.example.payment.controller;

import com.example.payment.dto.CreateOrderRequest;
import com.example.payment.dto.CreateOrderResponse;
import com.example.payment.dto.VerifyPaymentRequest;
import com.example.payment.entity.AppOrder;
import com.example.payment.service.PaymentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@CrossOrigin(origins = "http://localhost:3000") // Allow React frontend
public class PaymentController {

    private final PaymentService paymentService;

    // ✅ Explicit constructor injection (no Lombok)
    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    /** Step 1: Create a Razorpay order */
    @PostMapping("/process")
    public ResponseEntity<?> createOrder(@RequestBody CreateOrderRequest req) {
        try {
            CreateOrderResponse response = paymentService.createOrder(req);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Error creating order: " + e.getMessage());
            return ResponseEntity.status(500).body(error);
        }
    }

    /** Step 2: Verify Razorpay payment */
    @PostMapping("/verify")
    public ResponseEntity<?> verifyPayment(@RequestBody VerifyPaymentRequest req) {
        try {
            paymentService.verifyPayment(req);
            Map<String, String> success = new HashMap<>();
            success.put("message", "Payment verified successfully");
            return ResponseEntity.ok(success);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Payment verification failed: " + e.getMessage());
            return ResponseEntity.status(400).body(error);
        }
    }

    /** Step 3: Get all orders for a user */
    @GetMapping("/orders/{userId}")
    public ResponseEntity<List<AppOrder>> getOrdersByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(paymentService.getOrdersByUser(userId));
    }

    /** Step 4: Refund an order (dummy implementation) */
    @PostMapping("/refund")
    public ResponseEntity<?> refundOrder(@RequestParam Long orderId) {
        try {
            AppOrder refundedOrder = paymentService.refundOrder(orderId);
            return ResponseEntity.ok(refundedOrder);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Refund failed: " + e.getMessage());
            return ResponseEntity.status(400).body(error);
        }
    }
}
