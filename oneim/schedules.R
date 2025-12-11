library(lubridate)
library(ggplot2)
library(tidyverse)
library(dplyr)
library(anytime)



ois_schedule_dates_int <- function(frequency, day_index, size, fn_r, fn_w, start_date) {
  dates <- rep(NA, times=size)
  
  d = start_date
  for (i in 1:size) {
    dates[i] <- d
    d <- d + fn_w(frequency)
  }
  class(dates) <- "Date"
  return (dates)
}


# for given run date, return closest future date according to sched
OIS_GetNextStartDate <- function(frequency, sub_freq, tz, fn_r, fn_w, nr) {
  n <- lubridate::with_tz(Sys.time(), tz)
  parsed_date = anydate(nr)
  next_run = parsed_date - days(fn_r(parsed_date)) + days(sub_freq)
  today = as.Date(now())

  if ( next_run > today) {
    return(next_run)
  }
  else
  {
    delta = interval(next_run, today)
    periods = delta %/% fn_w(frequency)
    return ( next_run + fn_w((periods+1)*frequency) )
  }
  
}

ois_dday <- function(date){ return(0) }

OIS_GetDayRFn <- function(type){
  if ( type == "minute" | type == 'Min') {
    return (ois_dday)
  } else if ( type == "hour" | type == 'Hour') {
    return (ois_dday)
  } else if ( type == "day" | type == 'Day') {
    return (ois_dday)
  } else if ( type == "year" | type == 'Year') {
    return (yday)
  } else if ( type == "month" | type == 'Month') {
    return (mday)
  } else if ( type == "week" | type == 'Week') {
    return (wday)
  }
  return(NULL)
}

OIS_GetDateWFn <- function(type){
  if ( type == "day" | type == 'Day') {
    return (days)
  } else if ( type == "year" | type == 'Year') {
    return (years)
  } else if ( type == "month" | type == 'Month') {
    return (months)
  } else if ( type == "week" | type == 'Week') {
    return (weeks)
  }
  return(NULL)
}

OIS_Schedule_GetDates <- function(type, f, sf, time_of_day, tz, size, sd, lr, nr) {

  class(f) <- "double"
  
  # function to read days from date (day of week, day of month etc)
  f_r <- OIS_GetDayRFn(type)
  f_w <- OIS_GetDateWFn(type)

  # special handling of 'day' type, which likely has a null sub-freq
  sub_freq = sf
  if ( type == "day" | type == 'Day') {
    sf = 1
  }
  
  # choose an appropriate start date based on caller's next run, last run, start date
  next_run_date = ifelse( is.null(nr), ifelse( is.null(lr), sd, lr ), nr)
  next_run_date = OIS_GetNextStartDate(f, sub_freq, tz, f_r, f_w, next_run_date )
  
  return  (ois_schedule_dates_int(f, sub_freq, size, f_r, f_w, next_run_date))
}  


date_mapper <- function(v) {
  # [1] : id
  # [2] : type
  # [3] : frequency
  # [4] : sub-frequency
  # [5] : time-of-day
  # [6] : time zone offset (sec)
  # [7] : short name
  # [8] : start date
  # [9] : last run date
  # [10]: next run date
  
  size <- 10

  dates <- OIS_Schedule_GetTimes(v[2], v[3], v[4], v[5], v[6], size, v[8], v[9], v[10])

  df <- data.frame(
    id            = c(rep(v[1], times=size)),
    type          = c(rep(v[2], times=size)),
    freq          = c(rep(v[3], times=size)),
    sub_freq      = c(rep(v[4], times=size)),
    tod           = c(rep(v[5], times=size)),
    tz            = c(rep(v[6], times=size)),
    short_name    = c(rep(v[7], times=size)),
    start_date    = c(rep(v[8], times=size)),
    last_run_date = c(rep(v[9], times=size)),
    next_run_date = c(rep(v[10], times=size)),
    date = unlist(dates)
  )
  
  return(df)
}

calc_dates_for_schedule <- function(df){
  # transpose to collection of rows
  r <- df %>% pmap(~c(...))
  # new data frame for each row, with 10 calculated dates each row
  k <- map(r, date_mapper)

  # combine all df
  return( bind_rows(k) )
  
#  return(k)
}

# ==========================================



OIS_GetDateTimeWFn <- function(type){
  if ( type == "minute" | type == 'Min') {
    return (minutes)
  } else if ( type == "hour" | type == 'Hour') {
    return (hours)
  } else if ( type == "day" | type == 'Day') {
    return (days)
  } else if ( type == "year" | type == 'Year') {
    return (years)
  } else if ( type == "month" | type == 'Month') {
    return (months)
  } else if ( type == "week" | type == 'Week') {
    return (weeks)
  }
  return(NULL)
}


# for given run date, return closest future date according to sched
OIS_GetNextStartTime <- function(frequency, sub_freq, time_of_day, offset, fn_r, fn_w, nr) {

  parsed_time = anytime(nr)
  #parsed_time = mdy_hms(nr, tz="UTC")
  # add UTC offset (seconds)
  #parsed_time = parsed_time + strtoi(offset, 10)

  tod = time_of_day
  if (is.na(tod) | is_null(tod)) { 
      tod = "00:00" 
  } 
  
  h = strtoi(unlist(strsplit(tod, ":"))[1], 10)
  parsed_time = parsed_time - hours(hour(parsed_time)) + h*60*60
  m = strtoi(unlist(strsplit(tod, ":"))[2], 10)
  parsed_time = parsed_time - minutes(minute(parsed_time)) + m*60

  next_run = parsed_time - days(fn_r(parsed_time)) + days(sub_freq)
  today = now()

  if ( next_run > today ) {
    return(next_run)
  }
  else
  {
    delta = interval(next_run, today)
    periods = delta %/% fn_w(frequency)
    return ( next_run + fn_w((periods+1)*frequency) )
  }
  
}




OIS_schedule_timesx <- function(type, frequency, sub_frequency, time_of_day="0:00", tz="UTC", size=10) {
  timestamps <- rep(NA, times=size)
  
  if ( type == "hour")
  {
    # set target to today's date, current hour:minute
    t <- as.POSIXct(n)
    t <- t - seconds(second(t))
    
    for (i in 1:size) {
      timestamps[i] <- t
      t <- t + hours(frequency)
    }
    
  } 
  else if ( type == "day" | type == 'Day')
  {
    # split "1:23" into hour and minute
    target_time <- str_split_1(time_of_day, ':')
    
    # set target to today's date, with target hour:minute
    t <- as.POSIXct(n)
    t <- t - hours(hour(t)) + hours(strtoi(target_time[1]))
    t <- t - minutes(minute(t)) + minutes(strtoi(target_time[1]))
    t <- t - seconds(second(t))
    
    if ( t < n ) { t <- t + days(frequency)}
    for (i in 1:size) {
      timestamps[i] <- t
      t <- t + days(frequency)
    }
  }
  
  class(timestamps) <- "POSIXct"
  return( timestamps )
}

ois_schedule_times_int <- function(frequency, size, fn_r, fn_w, start_datetime) {
  times <- rep(NA, times=size)
  
  t = start_datetime
  for (i in 1:size) {
    times[i] <- t
    t <- t + fn_w(frequency)
  }
  class(times) <- "POSIXt"
  return (times)
}

OIS_Schedule_GetTimes <- function(type, f, sf, 
                                  time_of_day, offset,
                                  size, 
                                  sd, lr, nr) {
  
  class(f) <- "double"
  
  # function to read days from date (day of week, day of month etc)
  f_r <- OIS_GetDayRFn(type)
  f_w <- OIS_GetDateTimeWFn(type)
  
  sub_freq = sf
  if ( type == "day" | type == 'Day' | type == 'Hour' | type == 'Min' ) {
    sub_freq = 0
  }
  
  # choose an appropriate start date based on caller's next run, last run, start date
  next_run_time = ifelse( is.null(nr), ifelse( is.null(lr), sd, lr ), nr)
  next_run_time = OIS_GetNextStartTime(f, sub_freq, time_of_day, offset, f_r, f_w, next_run_time )
  
  return  (ois_schedule_times_int(f, size, f_r, f_w, next_run_time))
}  





