#' @title Creates a matrix of indicator values
#' @description Creates a matrix of zeros and ones, ones meaning being included in the interval
#' @param x A numeric vector for the time variable
#' @param knots A numeric vector that includes the knot locations
#'
pw_mat <- function(x, knots){
  
  matrix(unlist(lapply(x, in_interval, knots = knots)), nrow = length(x), byrow = TRUE)
  
}

#' @title CreateS a vector indicator values
#' @description Creates a vector of zeros and one, one meaning the value being included in the interval
#' @param x A numeric value for the time variable
#' @param knots A numeric vector that includes the knot locations
in_interval <- function(x, knots){
  
  intervals <- c(min(knots) - 10, knots, max(knots) + 10)#10 is arbitrary
  
  out <- rep(0, (length(knots) + 1))
    
  for(i in 1:(length(intervals) - 1)){
    if(x >= intervals[i] & x < intervals[i+1]){
      out[i] <- 1
    }
  }

  out
  
}

#'
#'
unique_length <- function(x){
  x %>% unique %>% length
}

#' Function to summarise the probability estimates
#' @param x a numeric vector
prob_summary <- function(x, probs = c(0.025, 0.5, 0.975)){
  #x <- x[x > 0 & x <= 1]
  out <- c(mean(x), quantile(x, probs))
  #names(out) <- c("mean", paste0((probs*100), "%"))
  return(out)
}

#' Function to combine prediction results
#' @param x a list
combine_pred <- function(x, iterations, nsubj, chunk_sizes){

  if(nsubj == 1){
    samples <- x[[1]]$ft_probs
    output  <- x[[1]]$ft_table
  }else{
    idlist  <- c()
    samples <- c()
    output  <- c()
    
    for(i in 1:iterations){
      
      iterations_nsubj <- chunk_sizes[i]#length(x[[i]])
      
      for(j in 1:iterations_nsubj){
        
        if(iterations_nsubj == 1){
          samples <- cbind(samples, x[[i]][[1]])
        }else{
          samples <- cbind(samples, x[[i]][[1]][[j]])
        }
        
      }
      
      idlist <- c(idlist, names(x[[i]][[1]]))
      output  <- rbind(output, x[[i]][[2]])
      
    }
    
    samples <- lapply(seq_len(ncol(samples)), function(i) samples[,i])
    names(samples) <- idlist    
  }
  
  return(list(samples = samples, output = output))

}

#' Combine B_samples
combine_bsamples <- function(x, iterations, nsubj, chunk_sizes, B_length){
  
  ndraw <- length(x[[1]]$B_sampled)
  
  out <- list()
  
  for(i in 1:iterations){
    
    for(ii in 1:chunk_sizes[i]){
      
      out_ii <- list()
      
      for(iii in 1:ndraw){
        
        out_ii[[iii]] <- switch(ifelse(B_length == 1, 1, 2), 
                                x[[i]]$B_sampled[[iii]][ii, , drop = FALSE], 
                                x[[i]]$B_sampled[[iii]][[ii]])
        
      }
      
      out <- c(out, out_ii)
    }
    
  }
  
  out2 <- list()
  
  for(i in 1:nsubj){
    out2[[i]] <- out[((i-1)*ndraw+1):(i*ndraw)]
  }
  
  return(out2)
  
}

# inverse of logit
expit <- function(x){
  exp(x)/(1+exp(x))
}

# function to create surv time and event indicator
stime_event_fun <- function(x, t_max, a){
  if(max(x) < t_max){
    matrix(c(max(x) + a, 1), ncol = 2)[rep(1, length(x)), ]
  }else{
    matrix(c(max(x), 0), ncol = 2)[rep(1, length(x)), ]
  }
}

# function to create a data frame for individual predictions -- useful for parallel computing

prep_data_indv_pred <- function(data, id, timeVar){
  
  id_unique <- unique(data[, id])
  
  data_out <- data.frame()
  
  for(i in id_unique){
    
    data_i <- data[data[, id] == i, ]
    
    for(j in 1:nrow(data_i)){
      data_i_j <- data_i[1:j, ]
      data_i_j[, id] <- paste0(i, "_", data_i_j[nrow(data_i_j), timeVar]) %>% rep(nrow(data_i_j))
      data_out <- rbind(data_out, data_i_j)
    }
    
  }
  
  return(data_out)
  
}


#' Sub-sample Bsamples

# subsample_B <- function(x, nsel_b){
#   
#   length_x <- length(x)
#   length_b <- dim(x[[1]])[1]
#   ind_sel <- lapply(1:length_x, function(i) sample(1:length_b, nsel_b, replace = FALSE))
#   
#   out <- list()
#   
#   for(i in 1:length_x){
#     out[[i]] <- x[[i]][ind_sel[[i]], , , drop = FALSE]
#   }
#   
#   return(out)
#   
# }

#' Sub-sample Bsamples applied one by one

subsample_B <- function(x, nsel_b){
  
  dim_x <- dim(x)
  nsubj <- dim_x[2]
  q <- dim_x[3]
  b_length <- dim_x[1]
  
  if(nsel_b %in% c("mean", "median", 1)){
    out <- matrix(NA, nsubj, q)
    for(i in 1:nsubj){
      if(nsel_b %in% c("mean", "median")){
        out[i, ] <- x[, i, ] %>% apply(MARGIN = 2, FUN = nsel_b)
      }else{
        out[i, ] <- x[sample(1:b_length, nsel_b, replace = FALSE), i, ]
      }
    }
  }else{# if nsel_b > 1, not mean or median
    out <- list()
    for(i in 1:nsubj){
      if(nsel_b == "all"){
        out[[i]] <- x[, i, ]
      }else{
        out[[i]] <- x[sample(1:b_length, nsel_b, replace = FALSE), i, ]
      }
    }    
  }

  return(out)
  
}
