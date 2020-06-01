s # 防止运行全部代码
# 测试代码（invalid）
SHOW CREATE TABLE covid2019;
ALTER TABLE covid2019 CHANGE COLUMN updateTime updateTime date;
ALTER TABLE covid2019 ADD COLUMN Date DATE NOT NULL;
UPDATE covid2019 SET Date = DATE_FORMAT(updateTime,'%Y-%m-%d');
ALTER TABLE covid2019 DROP COLUMN DATE;


# 查看infile outfile变量（invalid）
SET GLOBAL local_infile=ON;
SHOW VARIABLES LIKE '%secure%'
SHOW GLOBAL VARIABLES LIKE 'local_infile';


# 所有时间-省份-确诊人数
DROP TABLE IF EXISTS index_province_confirmedCount;
CREATE TABLE index_province_confirmedCount SELECT indextime ,provinceName ,province_confirmedCount FROM covid2019_3 GROUP BY indextime ,provinceName;

# 全部时间每日全国确诊人数
DROP TABLE IF EXISTS allcount;
CREATE TABLE allcount
SELECT indextime ,SUM(province_confirmedCount) sum_province_confirmedCount FROM index_province_confirmedCount GROUP BY indextime;


# 5月28日（最新时间）每个城市总确诊人数
DROP TABLE IF EXISTS index_province_city_confirm;
CREATE TABLE index_province_city_confirm
SELECT indextime ,provinceName ,cityName ,SUM(city_confirmedCount) sum_city_confirmedCount FROM covid2019_3 WHERE indextime = '2020-05-28' GROUP BY cityName;


# 全部时间每个城市确诊时间
DROP TABLE IF EXISTS alltime_index_province_city_confirm;
CREATE TABLE alltime_index_province_city_confirm
SELECT indextime ,provinceName ,cityName ,SUM(city_confirmedCount) sum_city_confirmedCount FROM covid2019_3 GROUP BY indextime ,cityName;


# 5月28日（最新时间）每个省份确诊人数
DROP TABLE IF EXISTS force_directed_graph;
CREATE TABLE force_directed_graph
SELECT indextime ,provinceName ,SUM(sum_city_confirmedCount) sum_city_confirmedCount FROM index_province_city_confirm GROUP BY provinceName;


# 查看数据行数
SELECT COUNT(*) FROM index_province_city_confirm;
SELECT COUNT(*) FROM force_directed_graph;


# 导入数据
SELECT indextime ,provinceName ,province_confirmedCount 
FROM covid2019_3 
GROUP BY provinceName,indextime
INTO OUTFILE '/tmp/mysqlee.csv' 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n';

SELECT COUNT(1) FROM covid2019_3 INTO OUTFILE '/tmp/omg1.xls'


SHOW CREATE TABLE covid2019_3;
-- 
-- CREATE TABLE `covid2019_3` (
--   `Unnamed: 0` text,
--   `provinceName` text,
--   `province_confirmedCount` double DEFAULT NULL,
--   `province_suspectedCount` double DEFAULT NULL,
--   `province_curedCount` double DEFAULT NULL,
--   `province_deadCount` double DEFAULT NULL,
--   `cityName` text,
--   `city_confirmedCount` double DEFAULT NULL,
--   `city_suspectedCount` double DEFAULT NULL,
--   `city_curedCount` double DEFAULT NULL,
--   `city_deadCount` double DEFAULT NULL,
--   `province_code` text,
--   `indextime` datetime DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8


# 更改时间格式
ALTER TABLE covid2019_3 CHANGE COLUMN indextime indextime DATE DEFAULT NULL;

# 基于allcount,进行两日数据对比
ALTER TABLE allcount DROP COLUMN diff;
ALTER TABLE allcount ADD COLUMN	diff DOUBLE NOT NULL;
ALTER TABLE allcount ADD COLUMN id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY;

# 辅助表
DROP TABLE IF EXISTS allcount_s;
CREATE TABLE allcount_s (
	id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	sum_province_confirmedCount DOUBLE NOT NULL
);

INSERT INTO allcount_s (sum_province_confirmedCount) VALUES (0);
INSERT INTO allcount_s (sum_province_confirmedCount) SELECT sum_province_confirmedCount FROM allcount;

# 更新diff数据
update allcount INNER JOIN allcount_s ON allcount.id = allcount_s.id SET allcount.diff = allcount_s.sum_province_confirmedCount;
ALTER TABLE allcount ADD COLUMN	diff_day DOUBLE NOT NULL;
UPDATE allcount SET diff_day = sum_province_confirmedCount - diff;
UPDATE allcount SET diff_day = 0 WHERE id =1;

