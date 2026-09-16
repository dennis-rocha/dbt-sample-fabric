with source as (
    -- Lê os dados da source documentada
    select *
    from {{ source('lakehouse_treinamento', 'taxi') }}
),
filtered_source as (
    -- Filtra apenas dados até 2019
    select *
    from source
    where year(lpepPickupDatetime) <= 2019
        or year(lpepDropoffDatetime) <= 2019
),
unique_row as (
    -- Remove duplicatas mantendo maior totalAmount
    select *,
        ROW_NUMBER() OVER (
            PARTITION BY vendorID,
            lpepPickupDatetime
            ORDER BY totalAmount DESC
        ) AS row_num
    from filtered_source
),
filtered as (
    -- Mantém apenas primeira linha de cada grupo
    select *
    from unique_row
    where row_num = 1
),
with_sk_id as (
    -- Cria surrogate key única para cada viagem
    select *,
        HASHBYTES(
            'SHA2_256',
            CONCAT_WS(
                '|',
                vendorID,
                CAST(lpepPickupDatetime AS VARCHAR(50))
            )
        ) AS sk_id
    from filtered
) -- Retorna todos os campos incluindo a surrogate key
select *
from with_sk_id
