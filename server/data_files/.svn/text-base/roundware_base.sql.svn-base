# ************************************************************
# Sequel Pro SQL dump
# Version 3408
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: 107.22.160.144 (MySQL 5.1.37-1ubuntu5.5)
# Database: roundware
# Generation Time: 2011-11-21 13:55:29 -0500
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table age
# ------------------------------------------------------------

DROP TABLE IF EXISTS `age`;

CREATE TABLE `age` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `htmlid` varchar(25) NOT NULL,
  `name` varchar(20) NOT NULL,
  `projectid` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `age` WRITE;
/*!40000 ALTER TABLE `age` DISABLE KEYS */;

INSERT INTO `age` (`id`, `htmlid`, `name`, `projectid`)
VALUES
	(1,'','Child',1),
	(2,'','Adult',1);

/*!40000 ALTER TABLE `age` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table category
# ------------------------------------------------------------

DROP TABLE IF EXISTS `category`;

CREATE TABLE `category` (
  `id` int(5) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `musicuri` varchar(300) DEFAULT NULL,
  `musicvolume` float DEFAULT NULL,
  `activeyn` varchar(1) NOT NULL,
  `projectid` int(5) NOT NULL,
  `ordering` int(3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;

INSERT INTO `category` (`id`, `name`, `musicuri`, `musicvolume`, `activeyn`, `projectid`, `ordering`)
VALUES
	(1,'Roundware','http://scapesaudio.dyndns.org:8000/ov.mp3',1,'Y',1,NULL);

/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table composition
# ------------------------------------------------------------

DROP TABLE IF EXISTS `composition`;

CREATE TABLE `composition` (
  `id` int(5) NOT NULL AUTO_INCREMENT,
  `categoryid` int(5) NOT NULL,
  `minvolume` float NOT NULL,
  `maxvolume` float NOT NULL,
  `minduration` bigint(20) NOT NULL,
  `maxduration` bigint(20) NOT NULL,
  `mindeadair` bigint(20) NOT NULL,
  `maxdeadair` bigint(20) NOT NULL,
  `minfadeintime` bigint(20) NOT NULL,
  `maxfadeintime` bigint(20) NOT NULL,
  `minfadeouttime` bigint(20) NOT NULL,
  `maxfadeouttime` bigint(20) NOT NULL,
  `minpanpos` float NOT NULL,
  `maxpanpos` float NOT NULL,
  `minpanduration` bigint(20) NOT NULL,
  `maxpanduration` bigint(20) NOT NULL,
  `repeatrecordings` varchar(1) DEFAULT 'N',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `composition` WRITE;
/*!40000 ALTER TABLE `composition` DISABLE KEYS */;

INSERT INTO `composition` (`id`, `categoryid`, `minvolume`, `maxvolume`, `minduration`, `maxduration`, `mindeadair`, `maxdeadair`, `minfadeintime`, `maxfadeintime`, `minfadeouttime`, `maxfadeouttime`, `minpanpos`, `maxpanpos`, `minpanduration`, `maxpanduration`, `repeatrecordings`)
VALUES
	(1,1,1,1,180000000000,180000000000,1000000000,3000000000,100000000,500000000,100000000,2000000000,0,0,5000000000,10000000000,'N');

/*!40000 ALTER TABLE `composition` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table demographic
# ------------------------------------------------------------

DROP TABLE IF EXISTS `demographic`;

CREATE TABLE `demographic` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `ageid` int(3) NOT NULL,
  `genderid` int(1) NOT NULL,
  `name` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `demographic` WRITE;
/*!40000 ALTER TABLE `demographic` DISABLE KEYS */;

INSERT INTO `demographic` (`id`, `ageid`, `genderid`, `name`)
VALUES
	(1,2,1,'Woman'),
	(2,2,2,'Man'),
	(3,1,1,'Girl'),
	(4,1,2,'Boy');

/*!40000 ALTER TABLE `demographic` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table event
# ------------------------------------------------------------

DROP TABLE IF EXISTS `event`;

CREATE TABLE `event` (
  `id` int(8) NOT NULL AUTO_INCREMENT,
  `eventtypeid` int(3) NOT NULL,
  `sessionid` varchar(30) CHARACTER SET utf8 DEFAULT NULL,
  `servertime` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `clienttime` varchar(30) CHARACTER SET utf8 DEFAULT NULL,
  `latitude` varchar(15) CHARACTER SET utf8 DEFAULT NULL,
  `longitude` varchar(15) CHARACTER SET utf8 DEFAULT NULL,
  `demographicid` varchar(10) DEFAULT NULL,
  `genderid` varchar(50) DEFAULT NULL,
  `ageid` varchar(100) DEFAULT NULL,
  `usertypeid` varchar(100) DEFAULT NULL,
  `questionid` varchar(50) DEFAULT NULL,
  `course` varchar(8) CHARACTER SET utf8 DEFAULT NULL,
  `haccuracy` varchar(8) CHARACTER SET utf8 DEFAULT NULL,
  `speed` varchar(8) CHARACTER SET utf8 DEFAULT NULL,
  `message` varchar(1000) DEFAULT NULL,
  `operationid` int(2) DEFAULT NULL,
  `udid` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `event` WRITE;
/*!40000 ALTER TABLE `event` DISABLE KEYS */;

INSERT INTO `event` (`id`, `eventtypeid`, `sessionid`, `servertime`, `clienttime`, `latitude`, `longitude`, `demographicid`, `genderid`, `ageid`, `usertypeid`, `questionid`, `course`, `haccuracy`, `speed`, `message`, `operationid`, `udid`)
VALUES
	(1,15,'1','2011-11-21 18:37:35',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
	(2,12,'5','2011-11-21 18:51:12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

/*!40000 ALTER TABLE `event` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table eventtype
# ------------------------------------------------------------

DROP TABLE IF EXISTS `eventtype`;

CREATE TABLE `eventtype` (
  `id` int(3) NOT NULL,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `eventtype` WRITE;
/*!40000 ALTER TABLE `eventtype` DISABLE KEYS */;

INSERT INTO `eventtype` (`id`, `name`)
VALUES
	(1,'GPS_FIX'),
	(2,'GPS_IDLE'),
	(3,'START_LISTEN'),
	(4,'STOP_LISTEN'),
	(5,'START_RECORD'),
	(6,'STOP_RECORD'),
	(7,'START_UPLOAD'),
	(8,'STOP_UPLOAD_SUCCESS'),
	(9,'STOP_UPLOAD_FAIL'),
	(10,'START_SESSION'),
	(11,'STOP_SESSION'),
	(12,'MODIFY_STREAM'),
	(13,'LOG_EVENT'),
	(14,'STOP_UPLOAD'),
	(15,'CLEANUP_STREAM');

/*!40000 ALTER TABLE `eventtype` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table gender
# ------------------------------------------------------------

DROP TABLE IF EXISTS `gender`;

CREATE TABLE `gender` (
  `id` int(1) NOT NULL AUTO_INCREMENT,
  `name` varchar(10) NOT NULL,
  `projectid` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `gender` WRITE;
/*!40000 ALTER TABLE `gender` DISABLE KEYS */;

INSERT INTO `gender` (`id`, `name`, `projectid`)
VALUES
	(1,'Female',0),
	(2,'Male',0);

/*!40000 ALTER TABLE `gender` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table project
# ------------------------------------------------------------

DROP TABLE IF EXISTS `project`;

CREATE TABLE `project` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `latitude` float(11,7) NOT NULL,
  `longitude` float(11,7) NOT NULL,
  `sharing_message` text COMMENT 'message to be shared with SHK',
  `out_of_range_message` text COMMENT 'message sent to client for display when client connects from outside range of particular project',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `project` WRITE;
/*!40000 ALTER TABLE `project` DISABLE KEYS */;

INSERT INTO `project` (`id`, `name`, `latitude`, `longitude`, `sharing_message`, `out_of_range_message`)
VALUES
	(1,'Roundware Project',0.0000000,0.0000000,'This is a test sharing message.','You are out of range!!!  Better try again.');

/*!40000 ALTER TABLE `project` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table question
# ------------------------------------------------------------

DROP TABLE IF EXISTS `question`;

CREATE TABLE `question` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `htmlid` varchar(15) NOT NULL,
  `text` varchar(200) NOT NULL,
  `categoryid` int(5) NOT NULL,
  `subcategoryid` int(3) NOT NULL,
  `ordering` tinyint(2) NOT NULL,
  `listenyn` varchar(1) DEFAULT NULL,
  `speakyn` varchar(1) DEFAULT NULL,
  `latitude` float(11,8) DEFAULT NULL,
  `longitude` float(11,8) DEFAULT NULL,
  `radius` int(8) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `question` WRITE;
/*!40000 ALTER TABLE `question` DISABLE KEYS */;

INSERT INTO `question` (`id`, `htmlid`, `text`, `categoryid`, `subcategoryid`, `ordering`, `listenyn`, `speakyn`, `latitude`, `longitude`, `radius`)
VALUES
	(1,'','This is a RW question.',1,1,0,'Y','Y',NULL,NULL,NULL),
	(2,'','Why is Roundware so cool?',1,1,0,'Y','Y',NULL,NULL,NULL);

/*!40000 ALTER TABLE `question` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table question_v
# ------------------------------------------------------------

DROP VIEW IF EXISTS `question_v`;

CREATE TABLE `question_v` (
   `id` INT(3) NOT NULL DEFAULT '0',
   `text` VARCHAR(200) NOT NULL,
   `categoryid` INT(5) NOT NULL,
   `subcategoryid` INT(3) NOT NULL,
   `listenyn` VARCHAR(1) DEFAULT NULL,
   `speakyn` VARCHAR(1) DEFAULT NULL,
   `radius` INT(8) DEFAULT NULL,
   `latitude` FLOAT(11) DEFAULT NULL,
   `longitude` FLOAT(11) DEFAULT NULL,
   `randordering` DOUBLE NOT NULL DEFAULT '0'
) ENGINE=MyISAM;



# Dump of table recording
# ------------------------------------------------------------

DROP TABLE IF EXISTS `recording`;

CREATE TABLE `recording` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `ageid` int(15) NOT NULL,
  `genderid` int(1) NOT NULL,
  `usertypeid` int(3) NOT NULL,
  `geonameid` int(8) NOT NULL,
  `latitude` float(11,7) NOT NULL,
  `longitude` float(11,7) NOT NULL,
  `questionid` int(3) NOT NULL,
  `filename` varchar(50) NOT NULL,
  `volume` float(5,3) NOT NULL DEFAULT '1.000',
  `projectid` int(3) NOT NULL,
  `categoryid` int(3) DEFAULT NULL,
  `subcategoryid` int(3) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `submittedyn` varchar(1) NOT NULL,
  `audiolength` bigint(13) DEFAULT NULL,
  `sessionid` varchar(50) NOT NULL,
  `comment` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `recording` WRITE;
/*!40000 ALTER TABLE `recording` DISABLE KEYS */;

INSERT INTO `recording` (`id`, `ageid`, `genderid`, `usertypeid`, `geonameid`, `latitude`, `longitude`, `questionid`, `filename`, `volume`, `projectid`, `categoryid`, `subcategoryid`, `created`, `submittedyn`, `audiolength`, `sessionid`, `comment`)
VALUES
	(1,2,2,2,0,42.4983521,-71.2806168,1,'rw_test_audio1.wav',1.000,1,1,1,'2011-11-21 13:37:25','Y',30751927438,'','');

/*!40000 ALTER TABLE `recording` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table session
# ------------------------------------------------------------

DROP TABLE IF EXISTS `session`;

CREATE TABLE `session` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `udid` varchar(50) DEFAULT NULL,
  `starttime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `stoptime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;



# Dump of table speaker
# ------------------------------------------------------------

DROP TABLE IF EXISTS `speaker`;

CREATE TABLE `speaker` (
  `id` tinyint(3) NOT NULL AUTO_INCREMENT,
  `activeyn` varchar(1) NOT NULL,
  `code` varchar(10) NOT NULL,
  `categoryid` int(3) NOT NULL,
  `latitude` float(11,8) NOT NULL,
  `longitude` float(11,8) NOT NULL,
  `maxdistance` int(10) NOT NULL,
  `mindistance` int(10) NOT NULL,
  `maxvolume` float(5,3) NOT NULL,
  `minvolume` float(5,3) NOT NULL,
  `uri` varchar(200) NOT NULL,
  `backupuri` varchar(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `speaker` WRITE;
/*!40000 ALTER TABLE `speaker` DISABLE KEYS */;

INSERT INTO `speaker` (`id`, `activeyn`, `code`, `categoryid`, `latitude`, `longitude`, `maxdistance`, `mindistance`, `maxvolume`, `minvolume`, `uri`, `backupuri`)
VALUES
	(1,'Y','GLOBAL',1,20.00000000,20.00000000,1000,1,1.000,1.000,'http://roundware.dyndns.org:8000/scapes1.mp3','http://scapesaudio.dyndns.org:8000/scapes1.mp3');

/*!40000 ALTER TABLE `speaker` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table subcategory
# ------------------------------------------------------------

DROP TABLE IF EXISTS `subcategory`;

CREATE TABLE `subcategory` (
  `id` int(5) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `categoryid` int(5) NOT NULL,
  `ordering` int(5) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `subcategory` WRITE;
/*!40000 ALTER TABLE `subcategory` DISABLE KEYS */;

INSERT INTO `subcategory` (`id`, `name`, `categoryid`, `ordering`)
VALUES
	(1,'Roundware',1,0);

/*!40000 ALTER TABLE `subcategory` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table usertype
# ------------------------------------------------------------

DROP TABLE IF EXISTS `usertype`;

CREATE TABLE `usertype` (
  `id` int(3) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `ordering` int(5) NOT NULL,
  `projectid` int(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOCK TABLES `usertype` WRITE;
/*!40000 ALTER TABLE `usertype` DISABLE KEYS */;

INSERT INTO `usertype` (`id`, `name`, `ordering`, `projectid`)
VALUES
	(1,'Official',0,1),
	(2,'Unofficial',0,1);

/*!40000 ALTER TABLE `usertype` ENABLE KEYS */;
UNLOCK TABLES;




# Replace placeholder table for question_v with correct view syntax
# ------------------------------------------------------------

DROP TABLE `question_v`;
CREATE ALGORITHM=UNDEFINED DEFINER=`round`@`localhost` SQL SECURITY DEFINER VIEW `question_v`
AS select
   `question`.`id` AS `id`,
   `question`.`text` AS `text`,
   `question`.`categoryid` AS `categoryid`,
   `question`.`subcategoryid` AS `subcategoryid`,
   `question`.`listenyn` AS `listenyn`,
   `question`.`speakyn` AS `speakyn`,
   `question`.`radius` AS `radius`,
   `question`.`latitude` AS `latitude`,
   `question`.`longitude` AS `longitude`,if((`question`.`id` = 23),10,(rand() + 10)) AS `randordering`
from `question` order by if((`question`.`id` = 23),10,(rand() + 10));

/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
