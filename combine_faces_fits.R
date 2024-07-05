combine_faces_fits <- function(root, ses, which.model, result_dir){
    all.files <- list.files(glue("{root}"), pattern=glue("session{ses}_{which.model}.*.csv"), full.names = T)
    df <- all.files %>% 
      pblapply(., FUN = read.csv) %>% 
      do.call(rbind, .)
  write.csv(faces.df, glue("{result_dir}/fits{Sys.Date()}.csv"), row.names = F)
}