
-- {{{ middle talbe: user_sync
DROP TABLE IF EXISTS user_sync;
CREATE TABLE `user_sync` (
`acct_id` int(11) NOT NULL DEFAULT '0',
`acct_name` varchar(64) CHARACTER SET latin1 NOT NULL DEFAULT '',
`domain_name` varchar(255) CHARACTER SET latin1 NOT NULL DEFAULT '',
`password` varchar(128) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '',
`action_name` varchar(64),
`action_time` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- {{{ triggers : sync_user_add  sync_user_del_mod

DELIMITER //
-- {{{ trigger_sync_user_add
DROP TRIGGER IF EXISTS trigger_sync_user_add //
CREATE TRIGGER trigger_sync_user_add AFTER INSERT
ON user_basic FOR EACH ROW
BEGIN
DECLARE $acct_name CHAR(64);
DECLARE $domain_name CHAR(255);
	SELECT acct_key.acct_name INTO $acct_name FROM acct_key WHERE acct_key.acct_id=NEW.acct_id;
	SELECT domain_key.domain_name INTO $domain_name FROM acct_key,domain_key
		WHERE domain_key.domain_id=acct_key.domain_id
		AND domain_key.domain_type=0   -- ignore domain alias
		AND acct_key.acct_id=NEW.acct_id;

	INSERT INTO user_sync
	VALUES (NEW.acct_id,$acct_name,$domain_name,NEW.password,'ADD',UNIX_TIMESTAMP() );	
END;

-- {{{ trigger_sync_user_del_mod
DROP TRIGGER IF EXISTS trigger_sync_user_del_mod //
CREATE TRIGGER trigger_sync_user_del_mod AFTER UPDATE
ON user_basic FOR EACH ROW
BEGIN
DECLARE $acct_name CHAR(64);
DECLARE $domain_name CHAR(255);

	-- delete user
	IF NEW.deleted_time > 0 THEN
        	SELECT domain_key.domain_name INTO $domain_name FROM domain_key
                	WHERE domain_key.domain_id=NEW.deleted_domain_id
			AND domain_key.domain_type=0;  -- ignore domain alias
		INSERT INTO user_sync
		VALUES (NEW.acct_id,NEW.deleted_acct_name,$domain_name,NEW.password,'DEL',UNIX_TIMESTAMP()); 
	-- modify user
        ELSEIF NEW.deleted_time = 0 && NEW.password <> OLD.password THEN
        	SELECT domain_key.domain_name INTO $domain_name FROM domain_key,acct_key
                	WHERE domain_key.domain_id=acct_key.domain_id
			AND domain_key.domain_type=0  -- ignore domain alias
			AND acct_key.acct_type=0      -- ignore user alias
			AND acct_key.acct_id=NEW.acct_id;
		SELECT acct_key.acct_name INTO $acct_name FROM acct_key
			WHERE acct_key.acct_id=NEW.acct_id;
               	INSERT INTO user_sync
               	VALUES (NEW.acct_id,$acct_name,$domain_name,NEW.password,'MOD',UNIX_TIMESTAMP() );
        END IF;
END;
