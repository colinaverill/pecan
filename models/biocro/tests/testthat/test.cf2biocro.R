context("check output from cf2biocro")

test.nc <- ncdf4::nc_open("data/urbana_subdaily_test.nc")
cfmet <- PEcAn.data.atmosphere::load.cfmet(test.nc, lat = 40.25, lon = -88.125,
										   start.date = "1979-05-05", end.date = "1979-07-01")
# ncdf4::nc_close(test.nc)
cfmet.hourly <- PEcAn.data.atmosphere::cfmet.downscale.time(cfmet)
biocro.met <- cf2biocro(cfmet.hourly)
test_that("cf2biocro creates BioCro compatible met from CF compliant file", {
  
  
  expect_true(all(c("year", "doy", "hour", "SolarR", "Temp", "RH", "WS", "precip") %in% 
    colnames(biocro.met)))
  
})


test_that("cf2biocro provides hours in 0:23 range", {
  tmp <- cfmet.hourly
  tmp$hour <- tmp$hour + 1
  
  expect_equal(range(tmp$hour), c(1, 24))
  biocro.met <- cf2biocro(tmp)
  expect_equal(range(biocro.met$hour), c(0, 23))
})
