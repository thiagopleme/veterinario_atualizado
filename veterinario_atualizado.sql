create schema veterinario;
use veterinario;

create table pacientes (
    id_paciente integer primary key auto_increment,
    nome varchar(100),
    especie varchar(50),
    idade integer
);


create table veterinarios (
    id_veterinario integer primary key auto_increment,
    nome varchar(100),
    especialidade varchar(50)
);


create table consultas (
    id_consulta integer primary key auto_increment,
    id_paciente integer,
    id_veterinario integer,
    data_consulta DATE,
    custo DECIMAL(10, 2),
    FOREIGN KEY (id_paciente) references pacientes(id_paciente),
    FOREIGN KEY (id_veterinario) references veterinarios(id_veterinario)
);


DELIMITER //

create procedure agendar_consulta(
    in p_id_paciente integer,
    in p_id_veterinario integer,
    in p_data_consulta date,
    in p_custo decimal (10, 2)
)
BEGIN
    insert into consultas (id_paciente, id_veterinario, data_consulta, custo)
    values (p_id_paciente, p_id_veterinario, p_data_consulta, p_custo);
END //

DELIMITER ;


DELIMITER //

create procedure atualizar_paciente(
    in p_id_paciente integer,
    in p_novo_nome varchar(100),
    in p_nova_especie varchar(50),
    in p_nova_idade integer
)
BEGIN
    update pacientes
    set nome = p_novo_nome, especie = p_nova_especie, idade = p_nova_idade
    where id_paciente = p_id_paciente;
END //

DELIMITER ;


DELIMITER //

create procedure remover_consulta(
    in p_id_consulta integer
)
BEGIN
    delete from consultas
    where id_consulta = p_id_consulta;
END //

DELIMITER ;

-- Parte 2 atividade_veterinário - tabela donos
create table donos (
    id_dono integer primary key auto_increment,
    nome varchar(100),
    telefone varchar(15)
);

-- Tabela de medicamentos
create table medicamentos (
    id_medicamento integer primary key auto_increment,
    nome varchar(100),
    dosagem varchar(50)
);

-- Tabela histórico
CREATE TABLE historico (
    id_historico integer primary key auto_increment,
    id_paciente integer,
    id_consulta integer,
    observacoes text,
    foreign key (id_paciente) references pacientes(id_paciente),
    foreign key (id_consulta) references consultas(id_consulta)
);

-- Criação triggers - Trigger para criar histórico após cada consulta
DELIMITER //

create trigger after_insert_consulta
after insert on consultas
FOR EACH ROW
BEGIN
    insert into historico (id_paciente, id_consulta, observacoes)
    values (NEW.id_paciente, NEW.id_consulta, 'Consulta realizada com sucesso');
END //

DELIMITER ;

-- Trigger para verificar se o custo da consulta é positivo
DELIMITER //
create trigger check_custo_consulta
before insert on consultas
FOR EACH ROW
BEGIN
    IF NEW.custo < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Custo da consulta deve ser positivo';
    END IF;
END //

DELIMITER ;

-- Trigger para notificar quando um paciente é atualizado
DELIMITER //
create trigger notify_paciente_update
after update on pacientes
FOR EACH ROW
BEGIN
    insert into historico (id_paciente, id_consulta, observacoes)
    values (NEW.id_paciente, NULL, CONCAT('Paciente atualizado: ', NEW.nome));
END //

DELIMITER ;

-- Trigger para evitar que um dono seja deletado se tiver pacientes

DElIMITER //
create trigger prevent_delete_dono
before delete on donos
FOR EACH ROW
BEGIN
    declare paciente_count integer;
    select COUNT(*) into paciente_count from pacientes where id_dono = OLD.id_dono;
    if paciente_count > 0 then
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Não é possível deletar dono com pacientes associados';
    END IF;
END //

DELIMITER ;

-- Trigger para auditar inserções de consultas
DELIMITER //
create trigger audit_insert_consulta
after insert on consultas
FOR EACH ROW
BEGIN
    insert into historico (id_paciente, id_consulta, observacoes)
    values (NEW.id_paciente, NEW.id_consulta, 'Consulta agendada');
END //

DELIMITER ;

-- Criando as procedures - adicionar dono
DELIMITER //

create procedure adicionar_dono(
    in p_nome varchar(100),
    in p_telefone varchar(15)
)
BEGIN
    insert into donos (nome, telefone) values (p_nome, p_telefone);
END //

DELIMITER ;

-- Atualizar medicamento
DELIMITER //
create procedure atualizar_medicamento(
    in p_id_medicamento INTEGER,
    in p_novo_nome varchar(100),
    in p_nova_dosagem varchar(50)
)
BEGIN
    update medicamentos
    set nome = p_novo_nome, dosagem = p_nova_dosagem
    where id_medicamento = p_id_medicamento;
END //

DELIMITER ;

-- Remover medicamento
DELIMITER //
create procedure remover_medicamento(
    in p_id_medicamento integer
)
BEGIN
    delete from medicamentos
    where id_medicamento = p_id_medicamento;
END //

DELIMITER ;

-- Registrar medicamento a uma consulta
DELIMITER //
create procedure registrar_medicamento_consulta(
    in p_id_consulta integer,
    in p_id_medicamento integer
)
BEGIN
    insert into historico (id_paciente, id_consulta, observacoes)
    values ((select id_paciente from consultas where id_consulta = p_id_consulta), p_id_consulta, CONCAT('Medicamento registrado: ', (select nome from medicamentos where id_medicamento = p_id_medicamento)));
END //

DELIMITER ;

-- Listar histórico de consultas
DELIMITER //
create procedure listar_historico_consultas(
    in p_id_paciente integer
)
BEGIN
    select * from historico where id_paciente = p_id_paciente;
END //

DELIMITER ;

-- Testando as procedures - Adicionar um dono
call adicionar_dono('João Silva', '11987654321');

call adicionar_dono('PEdro Teixeira', '11999089729');

-- Atualizar um medicamento
call atualizar_medicamento(1, 'Antibiótico X', '500mg');


-- Remover um medicamento
call remover_medicamento(1);

-- Listar histórico de consultas
call listar_historico_consultas(1);