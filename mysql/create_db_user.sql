-- 创建数据库
CREATE DATABASE `db_name` COLLATE utf8mb4_general_ci;

-- 创建用户
CREATE USER 'test_user'@'%' IDENTIFIED BY '123456';

-- 授权
GRANT ALL ON db_name.* TO 'test_user'@'%';

-- 刷新权限
flush privileges;
