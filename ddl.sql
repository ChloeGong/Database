-- table country
-- drop table country;
create table country(
  code varchar(3) primary key check(regexp_like(code, '^[A-Z]{3}$')),
  name varchar(20) not null
);

-- table place
-- drop table place;
create table place(
  name varchar(50) primary key,
  longitude double precision not null,
  latitude double precision not null,
  address varchar(50) 
-- constraint place_unique unique(longitude,latitude)
);

-- table accomodation
-- drop table accommodation;
create table accommodation(
  name varchar(50) primary key,
  constraint acc_fk foreign key (name) references place(name) on delete cascade -- on update casecade
);

-- table sportVenue
-- drop table sportVenue;
create table SportVenue(
  name varchar(50) primary key,
  constraint sv_fk foreign key (name) references place(name) on delete cascade -- on update casecade
);

-- table member
-- drop table member;
create table member(
  member_id varchar(10) primary key check(regexp_like(member_id, '^\d{10}$')),
  givenname varchar(20) not null,
  familyname varchar(20) not null,
  title varchar(10) check(title in('MR', 'MRS', 'MISS')),
  country varchar(3),
  accname varchar(50),
  constraint member_fk1 foreign key (country) references country(code) on delete cascade, -- on update casecade
  constraint member_fk2 foreign key (accname) references accommodation(name)
);

-- table athlete
-- drop table athlete;
create table Athlete(
  member_id varchar(10) primary key,
  constraint Athlete_fk foreign key (member_id) references member(member_id) on delete cascade -- on update casecade
);

-- table official
-- drop table official;
create table Official(
  member_id varchar(10) primary key,
  constraint Official_fk foreign key (member_id) references member(member_id) on delete cascade -- on update casecade
);

-- table staff
-- drop table staff;
create table Staff(
  member_id varchar(10) primary key,
  constraint Staff_fk foreign key (member_id) references member(member_id) on delete cascade -- on update casecade
);

-- table sport
-- drop table sport;
create table sport(
  name varchar(50) primary key
);

-- table event
-- drop table event;
create table event(
  name varchar(50) primary key,
  start_time timestamp,
  start_date date,
  result_type varchar(10) default 'NULL' check(result_type in('Gold','Silver','Bronze','NULL')),
  event_for varchar(50) not null,
  event_at varchar(50) not null,
  constraint event_fk1 foreign key (event_for) references sport(name) on delete cascade, -- on update casecade
  constraint event_fk2 foreign key (event_at) references SportVenue(name) on delete cascade -- on update casecade
);

-- table participates
-- drop table participates;
create table participates(
  member_id varchar(10) not null check(regexp_like(member_id, '^\d{10}$')), -- on update casecade
  name varchar(50) not null, -- on update casecade
  results integer not null check(results > 0),
  medal varchar(10) default 'NULL' check(medal in('Gold','Silver','Bronze','NULL')),
  constraint participates_pk primary key(member_id,name),
  constraint participates_fk1 foreign key (member_id) references Athlete(member_id) on delete cascade,
  constraint participates_fk2 foreign key (name) references event(name) on delete cascade
);

-- table run
-- drop table run;
create table run(
  member_id varchar(10) not null,  -- on update casecade
  name varchar(50) not null, -- on update casecade
  role varchar(50),
  constraint run_pk primary key(member_id, name),
  constraint run_fk1 foreign key (member_id) references Official(member_id) on delete cascade,
  constraint run_fk2 foreign key (name) references event(name) on delete cascade
);

-- table vehicle
-- drop table vehicle;
create table vehicle(
  code varchar(8) primary key check(regexp_like(code, '^[a-zA-Z]{8}$')),
  capacity integer not null check (capacity > 0)
);

-- table journey
-- drop table journey;
create table journey(
  start_date date not null,
  start_time timestamp not null,
  code varchar(8) not null, -- on update casecade
  to_place varchar(50), -- on update casecade
  from_place varchar(50), -- on update casecade
  nbooked integer default 0,
  constraint journey_pk primary key(start_date, start_time, code),
  constraint journey_fk1 foreign key (code) references vehicle(code) on delete cascade,
  constraint journey_fk2 foreign key (to_place) references place(name) on delete set null,
  constraint journey_fk3 foreign key (from_place) references place on delete set null
);

-- table book
-- drop table book;
create table book(
  member_id varchar(10) not null, -- on update casecade
  code varchar(8) not null,
  start_time timestamp not null, -- references journey(start_time) not null,
  start_date date not null, -- references journey(start_date) not null,
  smember_id varchar(10) not null, -- on update casecade
  booktime timestamp not null,
  constraint book_pk primary key(member_id, code, start_time, start_date, smember_id),
  constraint book_fk1 foreign key(code, start_time, start_date) references journey(code, start_time, start_date) on delete cascade, -- on update casecade
  constraint book_fk2 foreign key (member_id) references member on delete cascade,
  constraint book_fk3 foreign key (smember_id) references staff on delete set null
);

/* create trigger inserts
  after insert on country
  begin
  insert into member (member_id,country, givenname,familyname,title,accname)
  values('0000000010','UK','Emma','Stone','Miss','Wolli');
end; */

-- create view of athlete details
create view athlete_details as
	select member_id, givenname, familyname, title, country, accname, 
		count(case when medal='Gold' then 1 else null end) as Gold,
		count(case when medal='Silver' then 1 else null end) as Silver,
		count(case when medal='Bronze' then 1 else null end) as Bronze
	from member m join athlete a using (member_id) join participates p using (member_id)
	group by member_id, givenname, familyname, title, country, accname;

--create trigger journry nbooked
create or replace trigger journey_nbooked
after insert or delete or update on book
for each row
begin
    case
        when inserting then
            UPDATE journey 
            SET nbooked = nbooked + 1
            WHERE start_time = :n.start_time and start_date = :n.start_date and code = :n.code;
        when deleting then
            UPDATE journey 
            SET nbooked = nbooked - 1
            WHERE start_time = :n.start_time and start_date = :n.start_date and code = :n.code;
        when updating then 
            UPDATE journey 
            SET nbooked = nbooked
            WHERE start_time = :n.start_time and start_date = :n.start_date and code = :n.code;
    end case;
end;

/* --create trigger journry capacity
create trigger journey_nbooked
before insert on book-- or delete or update
referencing new as n
for each row
when((select count(*)
	  from book b
	  where b.start_date = n.start_date AND b.start_time = n.start_time AND b.code = n.code)
	  >=
	 (select capacity
      from vehicle v
      where v.code = n.code))
begin
  raise_application_error(-20000, 'Vehicle is full');
end; */

/* -- create assertion
create assertion journey_nbooked_capacity
check (not exists(select *
				  from (journey j natural join book b) natural join vehicle v
				  group by code, start_time, start_date
				  having count(*) > v.capacity)); */
