truncate table reviews;
insert into reviews (id, name, category, rating, price, currency, description)
select id, name, category, rating, price, currency, description from SCOTCH_REVIEWS
where rownum <= 50;
COMMIT;