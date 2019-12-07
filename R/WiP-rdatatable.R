## ----setup, include=FALSE------------------
knitr::opts_chunk$set(echo = TRUE, eval = TRUE) #, knitr.table.format = 'latex')
library(data.table)
library(ggplot2)
library(knitr)
library(kableExtra)
options(width=45)
knitr::opts_chunk$set(fig.pos = 'H')

# Reset the data.table print options.
options(datatable.print.topn=4, digits=3)

# Finding files using here package
library(here)
here()

# Making some aesthetic changes for this document
theme_set(theme_gray(base_size = 9))
update_geom_defaults("point", list(size = 0.5))
update_geom_defaults("boxplot", list(outlier.size = 0.5))


## head -n 4 ../data/WB-WiP.csv | cat -n |  sed 's/^[[:blank:]]*/ /g'


## ----readData, collapse=TRUE---------------
library(data.table)
library(here)
wip <- fread(here("data", "WB-WiP.csv"), 
             skip = 4, header = TRUE,
             check.names = TRUE)


## head -n 5 ../data/WB-WiP.csv | tail -c 31


## ----checkVxxNA, collapse=TRUE-------------
wip[, .N, by=.(V65)]


## ----rmCols, collapse=TRUE-----------------
wip[, c("Indicator.Name", "Indicator.Code", 
        "V65"):=NULL]
setnames(wip, c("Country.Name", "Country.Code"), 
              c("Country", "Code"))
head(names(wip))
tail(names(wip))


## ----meltwip, collapse=TRUE, message=FALSE, warning=FALSE----
WP <- melt(wip,
           id.vars = c("Country", "Code"),
           measure = patterns("^X"),
           variable.name = "YearC",
           value.name = c("pctWiP"),
           na.rm = TRUE)
WP


## ----finalTweaks, collapse=TRUE------------
WP[, `:=`(Year=as.numeric(gsub("X", "",  YearC)),
          Ratio = (100-pctWiP)/pctWiP)][
            , YearC:=NULL]
setcolorder(WP, c("Country", "Code", "Year", 
                  "pctWiP", "Ratio"))
# Look at the contents of WP
WP


## ----PTTable-------------------------------
WP[Country %in% "Portugal"]


## ----PTplot, fig.width=3, fig.height=2.3----
library(ggplot2)
library(magrittr)
WP[Country %in% "Portugal"] %>% 
ggplot(aes(Year, pctWiP)) +
  geom_line() + geom_point() +
  scale_y_continuous(limits=c(0, 50)) +
  ylab("% Women in Parliament")


## ----euPctPlot, fig.width=3.5, fig.height=2.9, cache=FALSE----
WP[Country %in% c("Portugal", "Sweden", "Spain",
     "Hungary", "Romania", "Finland", "Germany",
                           "European Union")] %>%
  ggplot(aes(Year, pctWiP, colour=Country)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks=seq(1990, 2020, 5)) +
  scale_y_continuous(limits=c(0, 50), 
                     breaks=seq(0, 50, by=10)) +
  ggtitle("Women in Parliament: EU Countries") +
  ylab("% Women in Parliament")


## ----allTopPct-----------------------------
WP[order(-pctWiP), head(.SD, 10)]


## ----allTopPctYear, collapse=TRUE----------
WP[order(Year, -pctWiP), head(.SD, 1), by = Year]


## ----mergeContinent------------------------
# Ensure that 'countrycode' package is installed.
# install.packages("countrycode")
library(countrycode)
cl <- as.data.table(codelist)[, .(continent, wb)]
setnames(cl, c("continent"), c("Continent"))
cWP <- merge(WP, cl, by.x = "Code", by.y = "wb",
             all.x = TRUE)


## ----allTopPctYearContinent, collapse=TRUE----
cWP[Year %in% c(1990, 2018) & !is.na(Continent)][
    order(Year, -pctWiP), head(.SD, 1), 
    by = .(Year, Continent)][
    order(Continent, Year), 
    .(Continent, Year, Country, pctWiP)]


## ----declinePct, collapse=TRUE-------------
dWP <- cWP[
  order(Country, Year), .SD[c(1,.N)], 
   by=Country][,
  pctDiff := pctWiP - shift(pctWiP), by=Country][
  pctDiff<0][
  order(pctDiff)]
dWP[!is.na(Continent),
    .(Country, pctWiP, pctDiff)]


## ----decline5pct, fig.width=3.5, fig.height=2.5----
# Select the countries to plot
dclpct <- unique(dWP[!is.na(Continent) &
                   pctDiff <= -5]$Country)

WP[Country %in% dclpct] %>%
  ggplot(aes(Year, pctWiP, colour=Country)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks=seq(1990, 2020, 5)) +
  scale_y_continuous(limits=c(0, 40),
  breaks=seq(0, 40, by=10)) +
  ggtitle("Women in Parliament: Decline >=5%") +
  ylab("% Women in Parliament")


## ----globalRank , collapse=TRUE------------
cWP[!is.na(Continent), 
    `:=`(RankG = rank(-pctWiP), TotalG = .N),
        by = .(Year)]


## ----globalRankPT , collapse=TRUE----------
cWP[Country=="Portugal", 
  .(Country, Year, pctWiP, Ratio, RankG, TotalG)][
  order(Year)]


## ----continentRank , collapse=TRUE---------
cWP[!is.na(Continent), 
    `:=`(RankC = rank(-pctWiP), TotalC = .N),
        by = .(Continent, Year)]


## ----continentRankPT , collapse=TRUE-------
cWP[Country=="Portugal", 
  .(Country, Year, pctWiP, Ratio, RankC, TotalC)][
  order(Year)]


## ----euRankplot, fig.width=3.5, fig.height=2.7----
cWP[Country %in% c("Portugal", "Sweden", "Spain",
  "Hungary", "Romania", "Finland", "Germany")] %>%
  ggplot(aes(Year, RankC, colour=Country)) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks=seq(1990, 2020, 5)) +
  scale_y_continuous(limits=c(0, 45), 
                     breaks=seq(0, 45, by=10)) +
  ggtitle("Women in Parliament: Ranked") +
  ylab("Rank in Europe")


## ----allTopRankYearContinent, collapse=TRUE, echo=2----
options(datatable.print.rownames=FALSE)
cWP[Year %in% c(1990, 2018) & RankC==1][
    order(Continent, Year), 
      .(Continent, Year, Country, pctWiP, RankC)]
options(datatable.print.rownames=TRUE)


## ----globalTrends, message=FALSE, fig.width=3, fig.height=2.5----
library(gghighlight)
cWP[is.na(Continent)] %>%
  ggplot(aes(Year, pctWiP, group=Country)) +
  geom_line() +
  gghighlight(Country=="World", 
              use_direct_label = FALSE, 
              use_group_by = FALSE) +
  scale_x_continuous(breaks=seq(1990, 2020, 5)) +
  scale_y_continuous(limits=c(0, 40), 
                     breaks=seq(0, 40, by=10)) +
  ggtitle("Women in Parliament: Global Trends") +
  ylab("% Women in Parliament")


## ----addWiPrect, echo=FALSE, out.width="100%"----
include_graphics(here("images", "Women_in_Parliament_rect.png"))

