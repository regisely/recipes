# non-numeric

    Code
      prep(impute_rec, training = credit_tr, verbose = FALSE)
    Condition
      Error in `check_type()`:
      ! All columns selected for the step should be numeric

# printing

    Code
      print(impute_rec)
    Output
      Recipe
      
      Inputs:
      
            role #variables
         outcome          1
       predictor         13
      
      Operations:
      
      Mean imputation for Age, Assets, Income

---

    Code
      prep(impute_rec)
    Output
      Recipe
      
      Inputs:
      
            role #variables
         outcome          1
       predictor         13
      
      Training data contained 2000 data points and 186 incomplete rows. 
      
      Operations:
      
      Mean imputation for Age, Assets, Income [trained]

# empty printing

    Code
      rec
    Output
      Recipe
      
      Inputs:
      
            role #variables
         outcome          1
       predictor         10
      
      Operations:
      
      Mean imputation for <none>

---

    Code
      rec
    Output
      Recipe
      
      Inputs:
      
            role #variables
         outcome          1
       predictor         10
      
      Training data contained 32 data points and no missing data.
      
      Operations:
      
      Mean imputation for <none> [trained]

# case weights

    Code
      impute_rec
    Output
      Recipe
      
      Inputs:
      
               role #variables
       case_weights          1
            outcome          1
          predictor         12
      
      Training data contained 2000 data points and 186 incomplete rows. 
      
      Operations:
      
      Mean imputation for Age, Assets, Income [weighted, trained]

---

    Code
      impute_rec
    Output
      Recipe
      
      Inputs:
      
               role #variables
       case_weights          1
            outcome          1
          predictor         12
      
      Training data contained 2000 data points and 186 incomplete rows. 
      
      Operations:
      
      Mean imputation for Age, Assets, Income [ignored weights, trained]

