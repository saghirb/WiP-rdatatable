# Exercises for "Women in Parliament - data.table"
# Source: https://github.com/saghirb/WiP-rdatatable

# Author: _Your Name Here_
#   Date: DD MON YYYY

# Importing the Women in Parliament (WiP) data

library(data.table)
library(here)
wip <- fread(here("data", "WB-WiP.csv"), skip = 4, header = TRUE)

# Look at the data
wip
str(wip)

# Fix column (variable names)
head(names(wip))
tail(names(wip))
names(wip) <- make.names(names(wip))
head(names(wip))
tail(names(wip))

# Continue from here....

