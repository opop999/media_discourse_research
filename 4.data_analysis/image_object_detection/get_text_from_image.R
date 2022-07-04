library(tesseract)

# For best and slowest model
download.file(
  "https://github.com/tesseract-ocr/tessdata_best/raw/main/ces.traineddata",
  destfile = "4.data_analysis/image_object_detection/data/ces.traineddata"
)

# For normal model
download.file("https://github.com/tesseract-ocr/tessdata/raw/main/ces.traineddata",
              destfile = "4.data_analysis/image_object_detection/data/ces.traineddata")


(
  model_cz <-
    tesseract(language = "ces", datapath = "4.data_analysis/image_object_detection/data/")
)

text <-
  ocr("4.data_analysis/image_object_detection/data/image_cz.png",
      engine = model_cz)

cat(text)
