USE TerminalAutomotriz;

DROP PROCEDURE IF EXISTS altaConcesionaria;
DELIMITER //

CREATE PROCEDURE altaConcesionaria(cuit VARCHAR(45), razonSocial VARCHAR(45), OUT res INT, OUT msg VARCHAR(45))
BEGIN
    DECLARE recv VARCHAR(45);
    SELECT cuit INTO recv
    FROM Concesionaria 
    WHERE Concesionaria.cuit = cuit;
    
    IF (recv IS NULL) THEN
        INSERT INTO Concesionaria (cuit, razonSocial, eliminado, fechaEliminado) VALUES (cuit, razonSocial, 0, NULL);
        SET res = 0;
        SET msg = '';
    ELSE
        SET res = -1;
        SET msg = 'CUIT YA EXISTENTE';
    END IF;
    
    SELECT res, msg;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS modificacionConcesionaria;
DELIMITER //
CREATE PROCEDURE modificacionConcesionaria(cuitP VARCHAR(45), razonSocialP VARCHAR(45), OUT res INT, OUT msg VARCHAR(45))
BEGIN
    DECLARE key_id INT;
    SELECT idConcesionaria INTO key_id
    FROM Concesionaria 
    WHERE Concesionaria.cuit = cuitP;
    
    IF (key_id IS NOT NULL) THEN
        UPDATE Concesionaria SET razonSocial=razonSocialP WHERE idConcesionaria=key_id;
        SET res = 0;
        SET msg = '';
    ELSE
        SET res = -1;
        SET msg = 'CUIT NO EXISTENTE';
    END IF;
    
    SELECT res, msg;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS bajaConcesionaria;
DELIMITER //
CREATE PROCEDURE bajaConcesionaria(cuitP VARCHAR(45), OUT res INT, OUT msg VARCHAR(45))
BEGIN
    DECLARE recv VARCHAR(45);
    DECLARE key_id INT;
    SELECT idConcesionaria, cuit INTO key_id, recv
    FROM Concesionaria 
    WHERE Concesionaria.cuit = cuitP;
    
    IF (recv IS NOT NULL) THEN
        UPDATE Concesionaria SET eliminado=1, fechaEliminado=now() WHERE idConcesionaria=key_id;
        SET res = 0;
        SET msg = '';
    ELSE
        SET res = -1;
        SET msg = 'CUIT NO EXISTENTE';
    END IF;
    
    SELECT res, msg;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS altaPedido;
DELIMITER //
CREATE PROCEDURE altaPedido(Concesionaria_cuit VARCHAR(45), OUT idP INT(11), OUT res INT, OUT msg VARCHAR(45))
BEGIN
    DECLARE recv VARCHAR(45);
    DECLARE key_id INT(11);
    DECLARE ultimo_pedido INT(11) DEFAULT NULL;
    SELECT idConcesionaria INTO key_id
    FROM Concesionaria 
    WHERE Concesionaria.cuit = Concesionaria_cuit;
    
    IF (key_id IS NOT NULL) THEN
        INSERT INTO Pedido (idConsecionaria, fecha) VALUES (key_id, now());
        SET ultimo_pedido = LAST_INSERT_ID();
        CALL altaVehiculo(idModeloTemp, cantidad, ultimo_detalle, id);
    ELSE
        SET res = -1;
        SET msg = 'No existe Concesionaria';
        SELECT res, msg;
    END IF;

    SET idP = ultimo_pedido;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS modificacionPedido;
DELIMITER //
CREATE PROCEDURE modificacionPedido(idPedido INT, modelo VARCHAR(45), cantidad INT, Concesionaria_cuit VARCHAR(45))
BEGIN 
    UPDATE pedido SET modelo=modeloP, cantidad=cantidadP, Concesionaria_cuit=Concesionaria_cuitP WHERE idPedido=idPedidoP;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS bajaPedido;
DELIMITER //
CREATE PROCEDURE bajaPedido(idPedido INT)
BEGIN
    update Pedido set eliminado=1,fechaEliminado=now() where idPedido=idPedidoP;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS altaDetallePedido;
DELIMITER //
CREATE PROCEDURE altaDetallePedido(modelo VARCHAR(45), cantidad INT(11), INOUT id INT(11))
BEGIN
    DECLARE idModeloTemp INT(11);
    DECLARE ultimo_detalle INT(11);
    SELECT idModelo INTO idModeloTemp
    FROM Modelo
    WHERE Modelo.descripcion = modelo;
    
    IF (idModeloTemp IS NULL) THEN
        INSERT INTO DetallePedido(Pedido_idPedido, Modelo_idModelo, cantidad) VALUES (id, idModeloTemp, cantidad);
        SET ultimo_detalle = LAST_INSERT_ID();
        CALL altaVehiculo(idModeloTemp, cantidad, ultimo_detalle, id);
        SET res = 0;
        SET msg = '';
    ELSE
        SET res = -1;
        SET msg = 'Ya existe modelo';
        SELECT res, msg;
    END IF;
END
//
DELIMITER ;

DROP PROCEDURE IF EXISTS modificacionDetallePedido;
DELIMITER //
CREATE PROCEDURE modificacionDetallePedido(idDetallePedido INT(11), modeloP VARCHAR(45), cantidadP INT(11), OUT res INT, OUT msg VARCHAR(45))
BEGIN
    DECLARE idModeloTemp INT(11);
    SELECT idModelo INTO idModeloTemp
    FROM Modelo
    WHERE Modelo.descripcion = modeloP;
    
    IF (idModeloTemp IS NOT NULL) THEN
        UPDATE DetallePedido SET Modelo_idModelo=idModeloTemp, cantidad=cantidadP WHERE DetallePedido.idDetallePedido=idDetallePedido;
        SET res = 0;
        SET msg = '';
    ELSE
        SET res = -1;
        SET msg = 'No existe modelo';
        SELECT res, msg;
    END IF;
END
//
DELIMITER ;

DROP PROCEDURE IF EXISTS bajaDetallePedido;
DELIMITER //
CREATE PROCEDURE bajaDetallePedido(idDetallePedido INT(11), OUT res INT, OUT msg VARCHAR(45))
BEGIN
    DECLARE idDetalleTemp INT(11);
    SELECT idDetallePedido INTO idDetalleTemp
    FROM Modelo
    WHERE DetallePedido.idDetallePedido = idDetallePedido;
    
    IF (idDetalleTemp IS NOT NULL) THEN
        UPDATE DetallePedido SET eliminado=1, fechaEliminado=now() WHERE DetallePedido.idDetallePedido=idDetallePedido;
        SET res = 0;
        SET msg = '';
    ELSE
        SET res = -1;
        SET msg = 'No existe Detalle Pedido';
        SELECT res, msg;
    END IF;
END
//
DELIMITER ;

DROP PROCEDURE IF EXISTS altaVehiculo;
DELIMITER //
CREATE PROCEDURE altaVehiculo(idModelo INT(11), cantidad INT(11), ultimo_detalle INT(11), INOUT id INT(11))
BEGIN
    DECLARE idPedidoParametro INTEGER DEFAULT 0;
    DECLARE idModeloParametro INTEGER;
    DECLARE modelo VARCHAR(45);
    DECLARE nCantidadDetalle INT;
    DECLARE nInsertados INT;
    DECLARE finished INT DEFAULT 0;
    DECLARE curDetallePedido
        CURSOR FOR
            SELECT Modelo_idModelo, cantidad FROM DetallePedido WHERE idDetallePedido = ultimo_detalle;
    DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET finished = 1;
    OPEN curDetallePedido;
    
    -- Obtenemos el modelo
    SELECT descripcion INTO modelo
    FROM Modelo
    WHERE Modelo.idModelo = idModelo;
    
    getDetalle: LOOP
        FETCH curDetallePedido INTO idModeloParametro, nCantidadDetalle;
        IF finished = 1 THEN
            LEAVE getDetalle;
        END IF;
        
        SET nInsertados = 0;
        WHILE nInsertados < nCantidadDetalle DO
            INSERT INTO Vehiculo(DetallePedido_idDetallePedido, DetallePedido_Modelo_idModelo, DetallePedido_Pedido_idPedido, descripcion) 
                VALUES (ultimo_detalle, idModeloParametro, id, modelo);
            SET nInsertados = nInsertados  + 1;
        END WHILE;
    END LOOP getDetalle;
    -- Elimino el cursor de memoria
    CLOSE curDetallePedido;
END
//
DELIMITER ;

DROP PROCEDURE IF EXISTS modificacionVehiculo;
DELIMITER //
CREATE PROCEDURE modificacionVehiculo(numChasis INT, modelo  VARCHAR(45), descripcion VARCHAR(45), idpedido INT, idmodelo INT )
BEGIN 
    update proveedor set numChasis=numChasisP, modelo=modeloP, descripcion=descripcionP, idpedido=idpedidoP,idmodelo=idmodeloP ;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS bajaVehiculo;
DELIMITER //
CREATE PROCEDURE bajaVehiculo(numChasis INT)
BEGIN 
    update Vehiculo set eliminado=1,fechaEliminado=now() where numChasis=numChasisP;
END
//
DELIMITER ;

DROP PROCEDURE IF EXISTS altaProvedor;
DELIMITER //
CREATE PROCEDURE altaProvedor(cuit INT, razonSocial VARCHAR(45), precio INT )
BEGIN 
    insert into provedor values(cuit, razonSocial ,precio);
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS modificacionProveedor;
DELIMITER //
CREATE PROCEDURE modificacionProveedor(cuit INT, razonSocial VARCHAR(45), precio INT )
BEGIN 
    update proveedor set cuit=cuitP, razonSocial=razonSocialP, razonSocial=Concesionaria_cuitP where cuit=cuitP;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS bajaProveedor;
DELIMITER //
CREATE PROCEDURE bajaProveedor(cuit INT)
BEGIN 
    update Proveedor set eliminado=1,fechaEliminado=now() where cuit=cuitP;
END
//
DELIMITER ;

DROP PROCEDURE IF EXISTS altaPartes;
DELIMITER //
CREATE PROCEDURE altaPartes(descripcion VARCHAR(45))
BEGIN 
    insert into Partes (descripcion)values(descripcion);
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS modificacionPartes;
DELIMITER //
CREATE PROCEDURE modificacionPartes(descripcionN VARCHAR(45), descripcionV varchar(45))
BEGIN 
    update Partes set descripcion=descripcionN where descripcion=descripcionV;
END
//
DELIMITER ;


DROP PROCEDURE IF EXISTS bajaPartes;
DELIMITER //
CREATE PROCEDURE bajaPartes(descripcion VARCHAR(45))
BEGIN 
    update Partes set eliminado=1,fechaEliminado=now() where descripcion=descripcion;
END
//
DELIMITER ;


