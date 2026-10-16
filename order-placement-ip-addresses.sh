#!/usr/bin/bash
docker exec -i order-placement jshell - << 'EOF'
import java.net.*;
try {
    InetAddress[] addresses = InetAddress.getAllByName("localhost");
    System.out.println("====== 🌍 EMPIRICAL LOCALHOST IP MAPPING ======");
    for (int i = 0; i < addresses.length; i++) {
        System.out.println("Position [" + i + "]: " + addresses[i].getHostAddress() + " (" + addresses[i].getClass().getSimpleName() + ")");
    }
} catch (Exception e) {
    e.printStackTrace();
}
/exit
EOF
