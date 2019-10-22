package com.firecode.k8s.deploy.dubboxml.service.impl;

import org.k8s.deploy.dubbo.api.DemoService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DemoServiceImpl implements DemoService {
	
	private static final Logger log = LoggerFactory.getLogger(DemoServiceImpl.class);

	@Override
	public String serviceName(String name) {
        log.debug("dubbo serviceName to : {}", name);
        return "k8s-deploy-dubboxml-service: "+name;
	}

}
