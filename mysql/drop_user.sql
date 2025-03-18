-- 先查询用户
SELECT User, Host FROM mysql.user WHERE User = 'test';

-- 查询用户权限
SELECT DISTINCT Db FROM mysql.db WHERE User = '用户名' AND Host = '主机名';

-- 查看用户权限
SHOW GRANTS FOR '用户名'@'%';

-- 谨慎执行

-- 删除用户
DROP USER 'test'@'%';

-- 删除用户权限
DELETE FROM mysql.db WHERE User = 'test' AND Host = '%';

-- 删除已不存在数据库
DELETE FROM mysql.db WHERE Db = 'test';
