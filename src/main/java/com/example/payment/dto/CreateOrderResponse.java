package com.example.payment.dto;

public class CreateOrderResponse {
    private String razorpayOrderId;
    private String keyId;
    private Double amount;
    private String currency;
    private Long appOrderId;

    public CreateOrderResponse() {}

    public CreateOrderResponse(String razorpayOrderId, String keyId, Double amount, String currency, Long appOrderId) {
        this.razorpayOrderId = razorpayOrderId;
        this.keyId = keyId;
        this.amount = amount;
        this.currency = currency;
        this.appOrderId = appOrderId;
    }

    public String getRazorpayOrderId() { return razorpayOrderId; }
    public void setRazorpayOrderId(String razorpayOrderId) { this.razorpayOrderId = razorpayOrderId; }

    public String getKeyId() { return keyId; }
    public void setKeyId(String keyId) { this.keyId = keyId; }

    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public Long getAppOrderId() { return appOrderId; }
    public void setAppOrderId(Long appOrderId) { this.appOrderId = appOrderId; }
}
