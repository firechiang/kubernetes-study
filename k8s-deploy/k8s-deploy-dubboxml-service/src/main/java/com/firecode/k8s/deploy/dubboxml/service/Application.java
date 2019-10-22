package com.firecode.k8s.deploy.dubboxml.service;
import java.io.IOException;

import org.springframework.context.support.ClassPathXmlApplicationContext;

public class Application {

	@SuppressWarnings("resource")
	public static void main(String[] args) throws IOException {
		System.setProperty("java.net.preferIPv4Stack", "true");
		ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("classpath:spring/provider.xml");
		context.start();
		System.out.println("Provider started.");
		// press any key to exit
		System.in.read(); 
	}
}
