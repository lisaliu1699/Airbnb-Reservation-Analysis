SELECT 
    COUNT(id_reservation)
FROM
    fct_bookings;
#70772
SELECT 
    COUNT(id_reservation)
FROM
    fct_cancellations;
#36502
SELECT 
    *
FROM
    fct_bookings
ORDER BY ds DESC;
SELECT 
    *
FROM
    fct_bookings
ORDER BY ds ASC;
#2017-04-12 to 2018-11-30
SELECT 
    DATEDIFF(max(ds),min(ds)) AS 'daydiff'
FROM
    fct_bookings;
# 587 days in between in this table
SELECT 
    *
FROM
    fct_cancellations
ORDER BY ds DESC;
SELECT 
    *
FROM
    fct_cancellations
ORDER BY ds ASC;
#from 2017-01-01 to 2018-11-30
SELECT 
    DATEDIFF(max(ds),min(ds)) AS 'daydiff'
FROM
    fct_cancellations;
# 698 days in between in this table
SELECT 
    COUNT(b.id_reservation)
FROM
    fct_bookings b
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation;
#70772, which is equal to the rows of fct_bookings
SELECT 
    COUNT(b.id_reservation)
FROM
    fct_bookings b
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
    where c.ds is not null;
#512 out of 70772 is cancelled
SELECT 
    *
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation;
#There are a total of 65931 reservations. 
#Here I got the 'joins' which the following project will base on. 
SELECT 
    e.id_entity,
    COUNT(b.id_reservation) AS 'number_order_entity',
    ROUND(COUNT(b.id_reservation) / (SELECT 
                    COUNT(b.id_reservation)
                FROM
                    fct_bookings b
                        INNER JOIN
                    dim_entities e ON b.id_entity = e.id_entity
                        INNER JOIN
                    dim_listings l ON b.id_listing = l.id_listing
                        LEFT JOIN
                    fct_cancellations c ON b.id_reservation = c.id_reservation) * 100,
            2) AS 'Percentage(%)'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
GROUP BY e.id_entity
ORDER BY number_order_entity DESC;
/*There are a total of 141 entities and top five in number of bookings are 52, B98, 8BE, 267 and 53, 
which count for 57% of bookings.*/
SELECT 
    l.dim_region,
    l.dim_country,
    COUNT(l.dim_country) AS 'number_country_listing',
    ROUND(COUNT(l.dim_country) / (SELECT 
                    COUNT(l.id_listing)
                FROM
                    fct_bookings b
                        INNER JOIN
                    dim_entities e ON b.id_entity = e.id_entity
                        INNER JOIN
                    dim_listings l ON b.id_listing = l.id_listing
                        LEFT JOIN
                    fct_cancellations c ON b.id_reservation = c.id_reservation) * 100,
            1) AS 'Percentage(%)'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
GROUP BY l.dim_region,l.dim_country
ORDER BY count(l.dim_region) DESC;
/*There are a total of 147 counties where listings are located in.
Top five are US, GB, DE, FR and AU and they count for 70% of listings.*/
#Scenario 1
SELECT 
    b.ds_checkin AS date,
    COUNT(b.id_reservation) AS 'Total Bookings',
    SUM(b.m_booking_value) AS 'Total Booking Value',
    SUM(b.m_booking_value) / SUM(b.m_nights_booked) AS 'Price per Night',
    SUM(b.m_nights_booked) / COUNT(b.id_reservation) AS 'Nights per Booking',
    SUM(b.m_booking_value) / SUM((b.m_guests) * (b.m_nights_booked))  AS 'Budget per Person per Night',
    COUNT(c.id_reservation) AS 'Total Cancellations',
    ROUND(COUNT(c.id_reservation) / COUNT(b.id_reservation) * 100,
            1) AS 'Cancellation Rate(%)'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    YEAR(b.ds_checkin) IN (2017 , 2018)
        AND l.dim_country IN ('US')
GROUP BY b.ds_checkin
ORDER BY SUM(b.m_booking_value) DESC;
/*2017-11-06 623355
2018-09-25 559418

I exported the csv file 'Booking Values in Spikes and Normal Days' and see the spikes more clearly in Tableau*/
#I researched these dates, but they are not national holiday or event days.So I guess the bump may be caused by specific group of clients
#First, I tried to find out what entities reserve rooms on these two days.
SELECT 
    e.id_entity
FROM
    dim_entities e
WHERE
    e.id_entity IN (SELECT DISTINCT
            b.id_entity
        FROM
            fct_bookings b
                INNER JOIN
            dim_entities e ON b.id_entity = e.id_entity
                INNER JOIN
            dim_listings l ON b.id_listing = l.id_listing
                LEFT JOIN
            fct_cancellations c ON b.id_reservation = c.id_reservation
        WHERE
            DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
                AND l.dim_country IN ('US'));
#23 entities
SELECT 
    b.id_entity,
    SUM(b.m_booking_value) AS 'total booking value',
    round(SUM(b.m_booking_value) * 100/ (SELECT 
            SUM(b.m_booking_value)
        FROM
            fct_bookings b
                INNER JOIN
            dim_entities e ON b.id_entity = e.id_entity
                INNER JOIN
            dim_listings l ON b.id_listing = l.id_listing
                LEFT JOIN
            fct_cancellations c ON b.id_reservation = c.id_reservation
        WHERE
            DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
                AND l.dim_country IN ('US')),1) AS 'percentage(%)'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US')
GROUP BY b.id_entity
ORDER BY SUM(b.m_booking_value) DESC;
/*Entity 'F6' reserve 77.2% out of all 23 entities
no 1: 77.2% F6
no 2: 7.4% 52
no 3: 3.1% 53
no 4: 2.7% B98

export 'Entities' total booking value in spike days */


/* try to get to know where the listing is located*/
SELECT 
    l.id_listing, l.dim_region, l.dim_state, l.dim_market
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
WHERE
    e.id_entity IN ('F6' , '52', '53', 'B98')
        AND DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US')
GROUP BY l.id_listing;

/*found: most are in SF, CA, North America*/
SELECT 
    l.dim_state,
    COUNT(l.dim_state),
    COUNT(l.dim_state) * 100 / (SELECT 
            COUNT(l.dim_state)
        FROM
            fct_bookings b
                INNER JOIN
            dim_entities e ON b.id_entity = e.id_entity
                INNER JOIN
            dim_listings l ON b.id_listing = l.id_listing
        WHERE
            e.id_entity IN ('F6' , '52', '53', 'B98')
                AND DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
                AND l.dim_country IN ('US')) AS Percentage
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
WHERE
    e.id_entity IN ('F6' , '52', '53', 'B98')
        AND DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US')
GROUP BY l.dim_state
ORDER BY COUNT(l.dim_state) DESC;
#export Listings by state.csv
SELECT 
    l.dim_market,
    COUNT(l.dim_market),
    COUNT(l.dim_market) * 100 / (SELECT 
            COUNT(l.dim_market)
        FROM
            fct_bookings b
                INNER JOIN
            dim_entities e ON b.id_entity = e.id_entity
                INNER JOIN
            dim_listings l ON b.id_listing = l.id_listing
        WHERE
            e.id_entity IN ('F6' , '52', '53', 'B98')
                AND DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
                AND l.dim_country IN ('US')) AS Percentage
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
WHERE
    e.id_entity IN ('F6' , '52', '53', 'B98')
        AND DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US')
GROUP BY l.dim_market
ORDER BY COUNT(l.dim_market) DESC;
#export Listings by market.csv
#The root causes to two main spikes are an annual event in San Francisco, CA and reservation
#Then I will do customer behavior study.
SELECT 
    l.id_listing,
    l.dim_room_type,
    l.dim_listing_tier,
    l.dim_cancellation_policy,
    l.dim_person_capacity,
    l.dim_is_active,
    l.dim_bedrooms
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
WHERE
    e.id_entity IN (SELECT 
            e.id_entity
        FROM
            fct_bookings b
                INNER JOIN
            dim_entities e ON b.id_entity = e.id_entity
                INNER JOIN
            dim_listings l ON b.id_listing = l.id_listing
        WHERE
            DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
                AND l.dim_country IN ('US'))
        AND DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US')
GROUP BY l.id_listing;
#export Listing preference.csv


SELECT 
     b.ds_checkin AS date,
    COUNT(b.id_reservation) AS 'Total Bookings',
     SUM(b.m_nights_booked) / COUNT(b.id_reservation) AS 'Nights per Booking',
    SUM(b.m_booking_value) AS 'Total Booking Value',
    SUM(b.m_booking_value) / SUM(b.m_nights_booked) AS 'Price per Night',
    SUM(b.m_nights_booked * l.dim_bedrooms) AS 'demand-room', 
    SUM(b.m_booking_value) / SUM(b.m_nights_booked * l.dim_bedrooms) AS 'Price per room per night',
    SUM((b.m_guests) * (b.m_nights_booked)) as 'demand-guest',
    SUM(b.m_booking_value) / SUM((b.m_guests) * (b.m_nights_booked)) AS 'Price per Person per Night',
    AVG(DATEDIFF(b.ds_checkin, b.ds)) AS 'Reservation beforehand',
    COUNT(c.id_reservation) AS 'Total Cancellations',
    AVG(DATEDIFF(b.ds_checkin, c.ds)) AS 'Cancellation beforehand',
    ROUND(COUNT(c.id_reservation) / COUNT(b.id_reservation) * 100,
            1) AS 'Cancellation Rate(%)'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    b.ds_checkin IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US')
        AND l.dim_bedrooms IS NOT NULL
GROUP BY b.ds_checkin
ORDER BY SUM(b.m_booking_value) DESC;
#export Reservation behavior for spikes.csv

SELECT 
    b.ds_checkin AS date,
    COUNT(b.id_reservation) AS 'Total Bookings',
     SUM(b.m_nights_booked) / COUNT(b.id_reservation) AS 'Nights per Booking',
    SUM(b.m_booking_value) AS 'Total Booking Value',
    SUM(b.m_booking_value) / SUM(b.m_nights_booked) AS 'Price per Night',
    SUM(b.m_nights_booked * l.dim_bedrooms) AS 'demand-room', 
    SUM(b.m_booking_value) / SUM(b.m_nights_booked * l.dim_bedrooms) AS 'Price per room per night',
    SUM((b.m_guests) * (b.m_nights_booked)) as 'demand-guest',
    SUM(b.m_booking_value) / SUM((b.m_guests) * (b.m_nights_booked)) AS 'Price per Person per Night',
    AVG(DATEDIFF(b.ds_checkin, b.ds)) AS 'Reservation beforehand',
    COUNT(c.id_reservation) AS 'Total Cancellations',
    AVG(DATEDIFF(b.ds_checkin, c.ds)) AS 'Cancellation beforehand',
    ROUND(COUNT(c.id_reservation) / COUNT(b.id_reservation) * 100,
            1) AS 'Cancellation Rate(%)'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    YEAR(b.ds_checkin) IN ('2017' , '2018')
        AND l.dim_country IN ('US')
        AND l.dim_bedrooms IS NOT NULL
GROUP BY b.ds_checkin
ORDER BY SUM(b.m_booking_value) DESC;
/*Reservation behavior for all.csv*/
/*As shown below, I tried to figure out the financial impact related to spike days*/

select SUM(b.m_booking_value) AS 'Total Booking Value'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    YEAR(b.ds_checkin) IN ('2017' , '2018')
        AND l.dim_country IN ('US');
select SUM(b.m_booking_value) AS 'Total Booking Value'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    b.ds_checkin IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US');
select 1182773/29844148 * 100 as 'Revenue Percentage';
#3.96% of all US market
select SUM(b.m_booking_value) AS 'Total Booking Value'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    YEAR(b.ds_checkin) IN ('2017' , '2018');
select 1182773/50590429 * 100 as 'Revenue Percentage';
#2.34% of global market

SELECT 
    e.*
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
WHERE
    e.id_entity IN (SELECT 
            e.id_entity
        FROM
            fct_bookings b
                INNER JOIN
            dim_entities e ON b.id_entity = e.id_entity
                INNER JOIN
            dim_listings l ON b.id_listing = l.id_listing
        WHERE
            DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
                AND l.dim_country IN ('US'))
        AND DATE(b.ds_checkin) IN ('2017-11-06' , '2018-09-25')
        AND l.dim_country IN ('US')
        group by e.id_entity;
        #export Entity info.csv
#scenario 2
  SELECT 
    b.id_entity
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    YEAR(b.ds) IN ('2018')
GROUP BY b.id_entity
ORDER BY SUM(b.m_booking_value) DESC
LIMIT 10;
  SELECT 
    b.ds_checkin AS date,
    COUNT(b.id_reservation) AS 'Total Bookings',
    SUM(b.m_nights_booked) / COUNT(b.id_reservation) AS 'Nights per Booking',
    SUM(b.m_booking_value) AS 'Total Booking Value',
    SUM(b.m_booking_value) / SUM(b.m_nights_booked) AS 'Price per Night',
    SUM(b.m_nights_booked * l.dim_bedrooms) AS 'demand-room',
    SUM(b.m_booking_value) / SUM(b.m_nights_booked * l.dim_bedrooms) AS 'Price per room per night',
    AVG(DATEDIFF(b.ds_checkin, b.ds)) AS 'Reservation beforehand',
    COUNT(c.id_reservation) AS 'Total Cancellations',
    AVG(DATEDIFF(b.ds_checkin, c.ds)) AS 'Cancellation beforehand',
    ROUND(COUNT(c.id_reservation) / COUNT(b.id_reservation) * 100,
            1) AS 'Cancellation Rate(%)'
FROM
    fct_bookings b
        INNER JOIN
    dim_entities e ON b.id_entity = e.id_entity
        INNER JOIN
    dim_listings l ON b.id_listing = l.id_listing
        LEFT JOIN
    fct_cancellations c ON b.id_reservation = c.id_reservation
WHERE
    b.id_entity IN ('52' , 'B98',
        '53',
        '267',
        '5693C',
        '8BE',
        '42E88',
        'F6',
        '183F',
        '3312')
         AND YEAR(b.ds_checkin) IN (2017 , 2018)
GROUP BY b.ds_checkin
order by b.ds_checkin;

#export Top 10 entities