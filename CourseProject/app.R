#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(mlbench)
library(caret)
library(pROC)

data("BreastCancer")
# exclude index variable and NA observations
dataset <- BreastCancer[!is.na(BreastCancer$Bare.nuclei),-1]

set.seed("2791")
trainIndex <- createDataPartition(dataset$Class, p=.5, list=FALSE)
training <- dataset[trainIndex,]
testing <- dataset[-trainIndex,]
trCtrl <- trainControl(summaryFunction = twoClassSummary, classProbs = TRUE)

# Define UI for application
ui <- fluidPage(
   
   # Application title
   titlePanel("Breast Cancer Diagnosis with Machine Learning"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
        checkboxGroupInput("features", 
                           label = h3("Features"),
                           choices = list("Cl thickness"=1,"Cell size"=2,
                                          "Cell shape"=3, "Marg adhesion"=4,
                                          "Epith. c. size"=5, "Bare nuclei"=6,
                                          "Bl. cromatin"=7, "Normal nucleoli"=8,
                                          "Mitoses"=9),
                           selected = c(1,2,3,4,5,6,7,8,9)),
        selectInput("model", label = h3("ML Algorithm"), 
                    choices = list("K-Nearest Neighbor" = 1, "Linear Discr. Analysis" = 2), 
                    selected = 1),
        actionButton("go", "Tune/Eval Model")
      ),
      
      # Show a plot of the ROC and AUC
      mainPanel(
        tabsetPanel(
          tabPanel("Results",
            h3("Test Data Performance"),
            # textOutput("features"), # verbatimTextOutput("features"),
            # verbatimTextOutput("model"),
            h4("ROC Curve"),
            plotOutput("rocplot", width = "25%"),
            h4("AUC"),
            textOutput("auc")
          ),
          tabPanel("Documentation", 
                   h3("Introduction"),
                   p("This interactive application allows you to train and evaluate alternative 
                     Machine Learning algorithms on the ", 
                     a("Wisconsin Breast Cancer Database.", 
                       href="https://archive.ics.uci.edu/ml/datasets/Breast+Cancer+Wisconsin+(Diagnostic)")),
                   p("The objective is to identify whether each of a number of cases is benign or malignant."),
                   h3("The Dataset"),
                   p("Data is available from package mlbench as the BreastCancer dataset. This is a data frame
                      with 699 observations on 11 variables, one being a character variable, 9 being ordered or
                      nominal and 1 target class."),
                   p("The original dataset is split into a training set, used to tune a model, and a testing set
                      used to evaluate model performance on trained model."),
                   h3("Using the Application"),
                   p("The application has two panels: a sidebar on the left where the user can control the 
                      parameters, and a main panel with two tabs. The main default tab ('Results') shows
                      performance results of the selected algorithm on the test set. The other tab ('Documentation')
                      is the one you're currently reading."),
                   h4("Feature Selection"),
                   p("You can manually control the set of features the model will be built on using the controls 
                     under the section",
                     strong("Features"),
                      ". By default, all features are selected and are used, but you can disable a subset of them 
                      by toggling the corresponding checkbox."),
                   h4("Algorithm Selection"),
                   p("Under the section", 
                      strong("ML Algorithm"), 
                      "you can choose which Machine Learning algorithm to train and test on this task: K-Nearest 
                      Neighbor and Linear Discriminat Analysis are two simple and popular alternatives which
                      are appropriate for this task."),
                   h4("Running"),
                   p("Click on the button", strong("Tune/Eval"), "to tune a model on the training set using a
                      bootstrapped resampling procedure to tune model parameters and then to train the model
                      on the whole training set using the chosen hyperparameter. The trained model is then used
                      to predict benign or malignant class probabilities on the test set."),
                   h4("Output"),
                   p("If no error occurs, under the tab", strong("Results"), "you'll see a plot of the ROC curve
                      relative to the test set showing how specificity relates to sensitivity by varying the 
                      probability decision threshold. Below the ROC curve, the page will show the corresponding
                      value of the Area Under the ROC Curve (AUC): values close to 0.5 reflect nearly random
                      prediction behaviour; close to 1 is nearly perfect classification.")
          )
        )
         
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  # features <- eventReactive(input$go, {
     # dat <- BreastCancer[!is.na(BreastCancer$Bare.nuclei),-1]
     # cat(file=stderr(), "Predictors: ", colnames(dat)[as.numeric(input$predictors)], "\n")
     # paste(colnames(dataset)[as.numeric(input$features)], collapse = " + ")
  #})
   
   model <- eventReactive(input$go, {
     method <- switch(input$model,
                      "1" = "knn",
                      "2" = "lda")
     formula <- paste("Class ~ ", paste(colnames(dataset)[as.numeric(input$features)], collapse = " + "), sep="")
     do.call("train", list(as.formula(formula), method = method, data = training, trControl = trCtrl, metric = "ROC"))
   })
  
   testroc <- eventReactive(input$go, {
      testProbs <- predict(model(), testing[, as.numeric(input$features)], type="prob")
      roc(testing$Class, testProbs[,1])
   })
   
   # output$features <- renderText({ features() })
   # output$model <- renderPrint({ summary(model()) })
   output$rocplot <- renderPlot({
     progress <- Progress$new(session, min=1, max=15)
     on.exit(progress$close())
     progress$set(message = 'Calculation in progress',
                  detail = 'This may take a while...')
     plot(testroc()) 
   })
   output$auc <- renderText({ testroc()$auc })
}

# Run the application 
shinyApp(ui = ui, server = server)

