package com.firecode.k8s.deploy.job.demo;

import java.util.Random;

/**
 * 使用 Kubernetes 任务调度定时执行该应用
 *
 */
public class App {
	
	public static void main(String[] args) throws InterruptedException {
		Random r = new Random();
		int waitTime = r.nextInt(20)+1000;
		System.out.println("Kubernetes调度定时任务开始执行，预计等待时间："+waitTime+"毫秒。");
		Thread.sleep(waitTime);
		System.out.println("Kubernetes调度定时任务执行完毕。");
	}
}
