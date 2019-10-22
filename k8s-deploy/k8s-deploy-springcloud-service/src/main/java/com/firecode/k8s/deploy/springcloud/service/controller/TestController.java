package com.firecode.k8s.deploy.springcloud.service.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {
	
	@Autowired
	private Environment environment;
	
	/**
	 * 获取服务名称
	 * @return
	 */
	@GetMapping("/serviceName")
	public String getServiceName() {
		
		return String.join("-", environment.getProperty("spring.application.name"),String.valueOf(System.currentTimeMillis()));
	}
}
