/*
Navicat MariaDB Data Transfer

Source Server         : foxconn_219
Source Server Version : 100310
Source Host           : 10.132.241.219:3306
Source Database       : sf_devel

Target Server Type    : MariaDB
Target Server Version : 100310
File Encoding         : 65001

Date: 2019-12-09 15:38:31
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for danny_chouqian_his
-- ----------------------------
DROP TABLE IF EXISTS `danny_chouqian_his`;
CREATE TABLE `danny_chouqian_his` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `emp_name` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `emp_no` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `type` int(11) DEFAULT 1 COMMENT '1.专题抽签',
  `type_remarks` varchar(50) COLLATE utf8mb4_bin DEFAULT '专题演讲',
  `creat_at` timestamp NULL DEFAULT current_timestamp(),
  `update_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=166 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='抽签程序专用';
