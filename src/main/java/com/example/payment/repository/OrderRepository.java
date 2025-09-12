package com.example.payment.repository;

import com.example.payment.entity.AppOrder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<AppOrder, Long> {
    List<AppOrder> findByUserId(Long userId);
    Optional<AppOrder> findByExternalOrderId(String externalOrderId);
}
