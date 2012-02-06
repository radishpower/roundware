DROP TABLE IF EXISTS age;
CREATE TABLE age (
  id int(3) NOT NULL AUTO_INCREMENT,
  name varchar(20) NOT NULL,
  projectid int(3) NOT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS artist;
CREATE TABLE artist (
  id int(5) NOT NULL AUTO_INCREMENT,
  firstname varchar(30) NOT NULL,
  lastname varchar(30) NOT NULL,
  categoryid varchar(3) NOT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS category;
CREATE TABLE category (
  id int(5) NOT NULL AUTO_INCREMENT,
  htmlid varchar(25) NOT NULL,
  name varchar(50) NOT NULL,
  activeyn varchar(1) NOT NULL,
  projectid int(5) NOT NULL,
  ordering int(3) DEFAULT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS composition;
CREATE TABLE composition (
  id int(5) NOT NULL AUTO_INCREMENT,
  categoryid int(5) NOT NULL,
  minvolume float NOT NULL,
  maxvolume float NOT NULL,
  minduration bigint(20) NOT NULL,
  maxduration bigint(20) NOT NULL,
  mindeadair bigint(20) NOT NULL,
  maxdeadair bigint(20) NOT NULL,
  minfadeintime bigint(20) NOT NULL,
  maxfadeintime bigint(20) NOT NULL,
  minfadeouttime bigint(20) NOT NULL,
  maxfadeouttime bigint(20) NOT NULL,
  minpanpos float NOT NULL,
  maxpanpos float NOT NULL,
  minpanduration bigint(20) NOT NULL,
  maxpanduration bigint(20) NOT NULL,
  repeatrecordings varchar(1) DEFAULT 'N',
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS gender;
CREATE TABLE gender (
  id int(1) NOT NULL AUTO_INCREMENT,
  htmlid varchar(10) NOT NULL,
  name varchar(10) NOT NULL,
  projectid int(3) NOT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS project;
CREATE TABLE project (
  id int(3) NOT NULL AUTO_INCREMENT,
  name varchar(50) NOT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS question;
CREATE TABLE question (
  id int(3) NOT NULL AUTO_INCREMENT,
  htmlid varchar(15) NOT NULL,
  text varchar(200) NOT NULL,
  categoryid int(5) NOT NULL,
  subcategoryid int(3) NOT NULL,
  imagefile varchar(50) DEFAULT NULL,
  ordering tinyint(2) NOT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS recording;
CREATE TABLE recording (
  id int(10) NOT NULL AUTO_INCREMENT,
  firstname varchar(25) NOT NULL,
  lastname varchar(25) NOT NULL,
  ageid int(15) NOT NULL,
  genderid int(1) NOT NULL,
  email varchar(50) DEFAULT NULL,
  usertypeid int(3) NOT NULL,
  geonameid int(8) NOT NULL,
  latitude float(11,7) NOT NULL,
  longitude float(11,7) NOT NULL,
  questionid int(3) NOT NULL,
  filename varchar(50) NOT NULL,
  volume float(5,3) NOT NULL DEFAULT '1.000',
  projectid int(3) NOT NULL,
  categoryid int(3) DEFAULT NULL,
  subcategoryid int(3) DEFAULT NULL,
  created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  submittedyn varchar(1) DEFAULT NULL,
  comment text,
  audiolength bigint(13) DEFAULT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS subcategory;
CREATE TABLE subcategory (
  id int(5) NOT NULL AUTO_INCREMENT,
  htmlid varchar(25) NOT NULL,
  name varchar(50) NOT NULL,
  categoryid int(5) NOT NULL,
  artistid int(5) DEFAULT NULL,
  ordering int(5) NOT NULL,
  PRIMARY KEY (id)
);

DROP TABLE IF EXISTS usertype;
CREATE TABLE usertype (
  id int(3) NOT NULL AUTO_INCREMENT,
  htmlid varchar(25) NOT NULL,
  name varchar(30) NOT NULL,
  ordering int(5) NOT NULL,
  projectid int(3) NOT NULL,
  PRIMARY KEY (id)
);
