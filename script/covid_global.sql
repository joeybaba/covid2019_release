s 

# 创建table
DROP TABLE IF EXISTS covid_global;
CREATE TABLE covid_global (
	updateTime DATE not null,
	continentName VARCHAR(100) not null,
	countryName VARCHAR(100) not null,
	province_zipCode DOUBLE not null,
	province_confirmedCount DOUBLE not null,
	province_curedCount DOUBLE not null,
	province_deadCount DOUBLE not null,
	cityName VARCHAR(100) not null
);
# 设置infile变量
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

# 导入数据
LOAD DATA LOCAL INFILE '/Users/joey/Desktop/superset csv/DXYArea_global.csv' INTO TABLE covid_global
FIELDS TERMINATED BY ',' ESCAPED BY '/'
LINES TERMINATED BY '\n' 
IGNORE 1 LINES

# 全球确诊人数概况图
DROP TABLE IF EXISTS global_force_directed_graph;
CREATE TABLE global_force_directed_graph 
SELECT updateTime, continentName, countryName, province_confirmedCount FROM covid_global GROUP BY updateTime, countryName;


# 各大洲确诊、治愈、死亡人数
DROP TABLE IF EXISTS global_allcount;
CREATE TABLE global_allcount
SELECT updateTime, continentName, SUM(province_confirmedCount) confirmed, SUM(province_curedCount) cured, SUM(province_deadCount) dead  FROM covid_global GROUP BY updateTime, continentName;


# 确诊人数变化趋势
ALTER TABLE global_allcount DROP COLUMN diff;
ALTER TABLE global_allcount ADD COLUMN diff DOUBLE NOT NULL;
ALTER TABLE global_allcount ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY;

DROP TABLE IF EXISTS allcount_s_2;
CREATE TABLE allcount_s_2 (
	id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	sum_province_confirmedCount DOUBLE NOT NULL
);

INSERT INTO allcount_s_2 (sum_province_confirmedCount) VALUES (0);
INSERT INTO allcount_s_2 (sum_province_confirmedCount) SELECT confirmed FROM global_allcount;

UPDATE global_allcount INNER JOIN allcount_s_2 ON global_allcount.id = allcount_s_2.id SET global_allcount.diff = allcount_s_2.sum_province_confirmedCount;
ALTER TABLE global_allcount ADD COLUMN	diff_day DOUBLE NOT NULL;
UPDATE global_allcount SET diff_day = confirmed - diff;
UPDATE global_allcount SET diff_day = 0 WHERE id =1;





