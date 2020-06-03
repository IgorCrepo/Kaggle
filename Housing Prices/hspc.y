import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.impute import SimpleImputer
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from xgboost import XGBRegressor
from lightgbm import LGBMRegressor
import math
import sklearn.metrics as metrics
from sklearn.model_selection import cross_val_score

"""
Housing Prices Competition
"""

# Read the data
X_full = pd.read_csv('../input/train.csv', index_col='Id')
X_test_full = pd.read_csv('../input/test.csv', index_col='Id')
print(X_full.shape)
print(X_test_full.shape)

# Remove rows with missing target, separate target from predictors
X_full.dropna(axis=0, subset=['SalePrice'], inplace=True)
X_full.drop_duplicates()

y = X_full.SalePrice
X_full.drop(['SalePrice'], axis=1, inplace=True)


# Break off validation set from training data
X_train_full, X_valid_full, y_train, y_valid = train_test_split(X_full, y, 
                                                                train_size=0.8, test_size=0.2,
                                                                random_state=63)


# "Cardinality" means the number of unique values in a column
# Select categorical columns with relatively low cardinality (convenient but arbitrary)
categorical_cols = [cname for cname in X_train_full.columns if
                    X_train_full[cname].nunique() < 100 and #100
                    X_train_full[cname].dtype == "object"]

# Select numerical columns
numerical_cols = [cname for cname in X_train_full.columns if 
                X_train_full[cname].dtype in ['int64', 'float64']]

# Keep selected columns only
my_cols = categorical_cols + numerical_cols
X_train = X_train_full[my_cols].copy()
X_valid = X_valid_full[my_cols].copy()
X_test = X_test_full[my_cols].copy()


# Preprocessing for numerical data
# numerical_transformer = SimpleImputer(strategy='median')
numerical_transformer = SimpleImputer(missing_values= np.nan, strategy='median')

# Preprocessing for categorical data
categorical_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='most_frequent')),
    ('onehot', OneHotEncoder(handle_unknown='ignore'))
])

# Bundle preprocessing for numerical and categorical data
preprocessor = ColumnTransformer(
    transformers=[
        ('num', numerical_transformer, numerical_cols),
        ('cat', categorical_transformer, categorical_cols)
    ])

my_model_1 = XGBRegressor(n_estimators = 4000 ,random_state = 0, min_samples_split=2, max_depth=2, min_child_weight=3, 
                    learning_rate =0.04,reg_alpha =5.2, reg_lambda = 1.68, base_score = 0.46, colsample_bylevel=0.226,
                    colsample_bytree=1, colsample_bynode=1,  ) # score = 14100 MAE = 11930   
                    
# Bundle preprocessing and modeling code in a pipeline
my_pipeline = Pipeline(steps=[('preprocessor', preprocessor),
                                ('model', my_model_1)
                                             ])

# Preprocessing of training data, fit model 
my_pipeline.fit(X_train, y_train)
# Preprocessing of validation data, get predictions
preds = my_pipeline.predict(X_valid)
# Evaluate the model
score = metrics.mean_absolute_error(y_valid, preds)
#print("X = " + str(x) + "\nMAE = " + str(score))
print(str(score))
print(my_pipeline.score(X_train, y_train))
print(my_pipeline.score(X_valid, y_valid))
print((my_pipeline.score(X_train, y_train))-(my_pipeline.score(X_valid, y_valid)))
print(((my_pipeline.score(X_train, y_train))-(my_pipeline.score(X_valid, y_valid)))*score)
#RMSE
score_2 = metrics.mean_squared_error(y_valid, preds)
print(math.sqrt(score_2))

# Preprocessing of test data, fit model
preds_test =my_pipeline.predict(X_test)
# Save test predictions to file
output = pd.DataFrame({'Id': X_test.index,
                       'SalePrice': preds_test})
output.to_csv('submission.csv', index=False)
