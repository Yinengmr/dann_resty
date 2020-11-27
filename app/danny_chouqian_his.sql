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


/*
Navicat MariaDB Data Transfer

Source Server         : localhost-root
Source Server Version : 100504
Source Host           : localhost:3306
Source Database       : test

Target Server Type    : MariaDB
Target Server Version : 100504
File Encoding         : 65001

Date: 2020-11-27 20:16:07
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for hw_article
-- ----------------------------
DROP TABLE IF EXISTS `hw_article`;
CREATE TABLE `hw_article` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `content` text DEFAULT NULL COMMENT '内容',
  `cate` varchar(255) DEFAULT '' COMMENT '所属分类',
  `hot` int(11) DEFAULT NULL COMMENT '浏览量',
  `creat_at` timestamp NULL DEFAULT current_timestamp(),
  `update_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COMMENT='文章表';

-- ----------------------------
-- Table structure for hw_comment
-- ----------------------------
DROP TABLE IF EXISTS `hw_comment`;
CREATE TABLE `hw_comment` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `article_id` int(11) DEFAULT NULL,
  `content` text DEFAULT NULL COMMENT '评论内容',
  `parent_id` int(11) DEFAULT NULL COMMENT '回复评论，若为空则是对文章的评论',
  `source_type` varchar(255) DEFAULT NULL COMMENT '来源（web端，APP，小程序等）',
  `creat_at` timestamp NULL DEFAULT current_timestamp(),
  `update_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COMMENT='评论表';

-- ----------------------------
-- Table structure for hw_likes
-- ----------------------------
DROP TABLE IF EXISTS `hw_likes`;
CREATE TABLE `hw_likes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `article_id` int(11) DEFAULT NULL COMMENT '文章id',
  `source_type` varchar(255) DEFAULT NULL COMMENT '来源（web端，APP端，小程序等）',
  `creat_at` timestamp NULL DEFAULT current_timestamp(),
  `update_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COMMENT='点赞表';

-- ----------------------------
-- Table structure for hw_user
-- ----------------------------
DROP TABLE IF EXISTS `hw_user`;
CREATE TABLE `hw_user` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL COMMENT '用户名称',
  `password` varchar(255) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL COMMENT '手机号',
  `email` varchar(100) DEFAULT '',
  `is_delete` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否删除，1-删除',
  `last_login_at` timestamp NULL DEFAULT current_timestamp(),
  `last_login_ip` varchar(40) DEFAULT NULL,
  `inline_time` int(11) NOT NULL DEFAULT 0 COMMENT '在线时长',
  `creat_at` timestamp NULL DEFAULT current_timestamp(),
  `update_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COMMENT='用户信息表';

-- ----------------------------
-- Table structure for hw_user_token
-- ----------------------------
DROP TABLE IF EXISTS `hw_user_token`;
CREATE TABLE `hw_user_token` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `status` int(1) DEFAULT 1 COMMENT '1 有效',
  `creat_at` timestamp NULL DEFAULT current_timestamp(),
  `update_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8 COMMENT='用户token表';
