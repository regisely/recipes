# quasiquotation

    Code
      prep(rec_1, training = iris_train)
    Condition
      Error in `all_of()`:
      ! object 'sepal_vars' not found

# printing

    Code
      print(rec)
    Output
      Recipe
      
      Inputs:
      
            role #variables
       predictor          5
      
      Operations:
      
      Variables selected Species, starts_with("Sepal"), Petal.Width

---

    Code
      prep(rec)
    Output
      Recipe
      
      Inputs:
      
            role #variables
       predictor          5
      
      Training data contained 150 data points and no missing data.
      
      Operations:
      
      Variables selected Species, Sepal.Length, Sepal.Width, petal_... [trained]

