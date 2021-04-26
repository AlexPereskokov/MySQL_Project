USE netflix

-- Cоздадим процедуру для предложения дружбы

DROP PROCEDURE IF EXISTS netflix.frendship_offers;

DELIMITER //
CREATE DEFINER=`root`@`localhost` PROCEDURE `netflix`.`frendship_offers`(IN for_user_id INT)
BEGIN
		-- общий город
	SELECT
		p2.user_id,
		concat(u.firstname, ' ', u.lastname)
	FROM profiles AS p
	JOIN profiles AS p2 ON p.city = p2.city
	JOIN users AS u ON u.id = p.user_id
	WHERE p.user_id = for_user_id
		AND p2.user_id <> for_user_id
	GROUP BY u.id
		UNION
		
	-- общие друзья
	SELECT
		fr3.target_user_id,
		concat(u.firstname, ' ', u.lastname)
	FROM friend_requests AS fr
	JOIN friend_requests AS fr2 ON (fr.target_user_id = fr2.initiator_user_id
		OR fr.initiator_user_id = fr2.target_user_id)
	JOIN friend_requests AS fr3 ON (fr3.target_user_id = fr2.initiator_user_id
		OR fr3.initiator_user_id = fr2.target_user_id)
	JOIN users AS u ON u.id = fr2.initiator_user_id
		OR u.id = fr2.target_user_id
	WHERE fr2.status = 'approved' -- оставляем только подтвержденную дружбу
	AND fr3.status = 'approved'
	AND fr3.target_user_id <> for_user_id
	AND (fr.target_user_id = for_user_id
		OR fr.initiator_user_id = for_user_id) -- исключим себя
	order by rand() -- будем брать всегда случайные записи
	limit 5 -- ограничим всю выборку до 5 строк 
	;
END//
DELIMITER ;

-- Вызов процедуры

CALL netflix.frendship_offers(1);

-- Создадим триггер на 0 значение оценки фильма

DROP TRIGGER IF EXISTS nullstarTrigger;

delimiter //

CREATE TRIGGER nullstarTrigger BEFORE INSERT ON stars_movie
FOR EACH ROW
BEGIN
	IF (NEW.stars = '0') THEN 
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Trigger Warning! NULL is incorrect star!';
	END IF;
END //

delimiter ;

-- проверка

INSERT INTO `stars_movie` VALUES 
('10001','440','1','0','2004-03-29 19:55:56'); --  выведение сообщения ошибки
