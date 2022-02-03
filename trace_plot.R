###############################
# Create a plot for trace.txt #
###############################

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(gt)
})

# Read files
table = read.table("<PATH-TO>/trace.txt", sep = "\t", header = T)
flags = read.table("<PATH-TO>/flags.txt", sep = "\n", stringsAsFactors = F)$V1

table = table %>% select(name, realtime)

# Create and modify class
table$name <- gsub("vep \\((.*) [0-9]*\\)", "\\1", table$name)
table$class <- gsub(flags[1], "CLINVAR", table$name)
table$class <- gsub(flags[2], "TOPMED", table$class)
table$class <- gsub(flags[3], "UK10K", table$class)
table$class <- gsub(" ", " + ", table$class)
table[table$class == "",]$class = "Baseline"

# From hour to minutes
table$realtime <- parse_date_time(table$realtime, c("HMS", "HM"))
table$class <- reorder(table$class, table$realtime, median)

fig1 = table %>%
  ggplot(aes(realtime, class, fill=class, color=class)) +
  geom_boxplot(alpha = .5) +
  geom_jitter() +
  theme_classic() +
  labs(x = "Runtime (Hours)", y = "Different combinations of `--custom` usage",
       title = "VEP runtimes") +
  theme(legend.position = 'none')

png(filename = "~/Downloads/Benchmark_different_customs_BP.png",
    width = 1000, height = 800, res = 200)
fig1
dev.off()


## Table
fig2 = table %>%
  group_by(class) %>% summarise(time = median(realtime)) %>%
  mutate(diff = as.duration(as.difftime(time - time[1], units = "mins"))) %>%
  mutate(time = time %>% format("%H:%M:%S")) %>%
  gt() %>%
  tab_header(
    title = "Different combinations of `--custom` usage"
  ) %>%
  cols_label(
    class = "Class",
    time = "Time (hours)",
    diff = "Difference from Baseline"
  ) %>%
  gt::tab_footnote(footnote = "Baseline = Running without any additional flags", locations = cells_column_labels(columns = class)) %>%
  gt::tab_footnote(footnote = paste("CLINVAR = ", flags[1]), locations = cells_column_labels(columns = class)) %>%
  gt::tab_footnote(footnote = paste("TOPMED = ", flags[2]), locations = cells_column_labels(columns = class)) %>%
  gt::tab_footnote(footnote = paste("UK10K = ", flags[3]), locations = cells_column_labels(columns = class))

# Figure 2 was saved manually.