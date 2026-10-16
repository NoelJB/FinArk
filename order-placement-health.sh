#!/usr/bin/env bash
docker exec -i order-placement jshell -R-Djava.net.preferIPv4Stack=true - << 'EOF'
import java.net.http.*;
import java.net.*;
import java.time.Duration;

var client = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

// 💡 Test Target A: localhost
try {
    System.out.println("⏳ Testing Target A (localhost)...");
    var start = System.currentTimeMillis();
    var reqA = HttpRequest.newBuilder().uri(URI.create("http://localhost:8080/actuator/health/liveness")).build();
    var resA = client.send(reqA, HttpResponse.BodyHandlers.discarding());
    System.out.println("✅ Target A Success! Status: " + resA.statusCode() + " (Took " + (System.currentTimeMillis() - start) + "ms)");
} catch (Exception e) {
    System.out.println("❌ Target A FAILED: " + e.getClass().getName() + " - " + e.getMessage());
}

// 💡 Test Target B: 127.0.0.1
try {
    System.out.println("\n⏳ Testing Target B (127.0.0.1)...");
    var start = System.currentTimeMillis();
    var reqB = HttpRequest.newBuilder().uri(URI.create("http://127.0.0.1")).build();
    var resB = client.send(reqB, HttpResponse.BodyHandlers.discarding());
    System.out.println("✅ Target B Success! Status: " + resB.statusCode() + " (Took " + (System.currentTimeMillis() - start) + "ms)");
} catch (Exception e) {
    System.out.println("❌ Target B FAILED: " + e.getClass().getName() + " - " + e.getMessage());
}

/exit
EOF
