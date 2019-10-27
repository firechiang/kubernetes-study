package com.firecode.k8s.deploy.dubboxml.service;

import org.k8s.deploy.dubbo.api.DemoService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class DemoController {

    private static final Logger log = LoggerFactory.getLogger(DemoController.class);

    @Autowired
    private DemoService demoService;

    @RequestMapping("/hello")
    @ResponseBody
    public String sayHello(@RequestParam String name) {

        log.debug("say hello to :{}", name);

        String message = demoService.serviceName(name);

        log.debug("dubbo result:{}", message);

        return message;

    }
}
