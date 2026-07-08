CREATE TABLE IF NOT EXISTS dw.dim_canal
(
    canal    VARCHAR(50)
  , subcanal VARCHAR(50)
  , PRIMARY KEY (canal, subcanal)
);