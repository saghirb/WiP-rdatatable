## Run all files to prepare "Women in Parliament -- data.table"

# Setup
library(here)
library(pdftools)
library(magick)
library(magrittr)

# Confirm directory location
here()

# Download the zipped data file and extract the files to the "data/" directory.
# First empty the "share"data/ folder and recreate the directory structure.
unlink(here("data/"), recursive = TRUE, force = TRUE)
dir.create(here("data"))

tmpZip <- tempfile()
download.file("http://api.worldbank.org/v2/en/indicator/SG.GEN.PARL.ZS?downloadformat=csv",
              destfile = tmpZip)
unzip(tmpZip, exdir = here("data"))

WiPDataFile <- list.files(path = here("data"), pattern = "^API")
file.copy(here("data", WiPDataFile), here("data", "WB-WiP.csv"))

# Render the guide and produce the zip file for distribution.
rmarkdown::render(here("doc", "WiP-rdatatable.Rmd"))

# Create an image for the README.md file
  tempPNGs <- rep(tempfile(), 2)
  pdf_convert(here("doc", "WiP-rdatatable.pdf"), "png", pages = 1:2,
              filenames = tempPNGs)

  img1 <- image_read(tempPNGs[1])
  img2 <- image_read(tempPNGs[2])

  image_append(c(image_border(img1, geometry = "3x3"),
                 image_border(img2, geometry = "3x3"))) %>%
    image_write(.,path=here("images", "WiP-dt-guide.png"), format="png")

# Image for GitHub settings
  ghTemp <- tempfile()
  test <- pdf_convert(here("doc", "WiP-rdatatable.pdf"), "png", pages = 1, dpi = 155,
                      filenames = ghTemp)

  image_read(ghTemp) %>%
    image_crop(geometry_area(1280, 640, 0, 0), repage = FALSE) %>%
    image_write(., path=here("images", "WiPdt-GitHub.png"), format="png")

# Extract the R code from Rmd file
knitr::purl(here("doc", "WiP-rdatatable.Rmd"), output=here("R", "WiP-rdatatable.R"))

# Create zip files to share with participants
# First empty the share folder and recreate the directory structure.
unlink(here("Share/"), recursive = TRUE, force = TRUE)
dir.create(here("Share"))
dir.create(here("Share", "data"))

# Populate the Share directories
file.copy(here("doc", "WiP-rdatatable.pdf"), here("Share"))
file.copy(here("doc", "WiP-Exercise.R"), here("Share"))
file.copy(here("data", "WB-WiP.csv"), here("Share", "data"))

# Creating (initialising) an RStudio project
rstudioapi::initializeProject(path = here("Share"))
file.rename(here("Share", "Share.Rproj"), here("Share", "WiP-dt.Rproj"))

# Using here() function with zip results in full paths in the zip files :(
# Not beautiful: Using setwd to overcome the full paths issue above.
setwd(here("Share"))
zip(here("Share", "WiP-rdatatable.zip"), "./", extras = "-FS")
setwd(here())
