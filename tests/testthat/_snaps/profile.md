# bad values

    Code
      sacr_rec %>% step_profile(everything(), profile = vars(sqft)) %>% prep(data = Sacramento)
    Condition
      Error in `prep()`:
      ! The profiled variable cannot be in the list of variables to be fixed.

---

    Code
      sacr_rec %>% step_profile(everything(), profile = age) %>% prep(data = Sacramento)
    Condition
      Error in `structure()`:
      ! object 'age' not found

---

    Code
      sacr_rec %>% step_profile(sqft, beds, price, profile = vars(zip, beds)) %>%
        prep(data = Sacramento)
    Condition
      Error in `prep()`:
      ! Only one variable should be profiled

---

    Code
      sacr_rec %>% step_profile(city, profile = vars(sqft), pct = -1) %>% prep(data = Sacramento)
    Condition
      Error in `step_profile()`:
      ! `pct should be on [0, 1]`

---

    Code
      sacr_rec %>% step_profile(city, profile = vars(sqft), grid = 1:3) %>% prep(
        data = Sacramento)
    Condition
      Error in `step_profile()`:
      ! `grid` should have two named elements. See ?step_profile

---

    Code
      sacr_rec %>% step_profile(city, profile = vars(sqft), grid = list(pctl = 1,
        len = 2)) %>% prep(data = Sacramento)
    Condition
      Error in `step_profile()`:
      ! `grid$pctl should be logical.`

---

    Code
      fixed(rep(c(TRUE, FALSE), each = 5))
    Condition
      Error in `error_cnd()`:
      ! Conditions must have named data fields

# printing

    Code
      print(num_rec_1)
    Output
      Recipe
      
      Inputs:
      
            role #variables
       predictor         10
      
      Operations:
      
      Profiling data set for sqft

---

    Code
      print(num_rec_2)
    Output
      Recipe
      
      Inputs:
      
            role #variables
       predictor         10
      
      Training data contained 20 data points and no missing data.
      
      Operations:
      
      Profiling data set for sqft [trained]

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
      
      Profiling data set for mpg

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
      
      Profiling data set for mpg [trained]

