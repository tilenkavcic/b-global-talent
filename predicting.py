import numpy as np
import requests
import pandas as pd
from matplotlib import pyplot
from numpy import concatenate
from pmdarima import auto_arima
import matplotlib.pyplot as plt
from math import sqrt
from sklearn.metrics import mean_squared_error, accuracy_score
from xgboost import XGBClassifier


def sarimax_solar(df_hist, df_pred):
    # Split to train test
    train = df_hist
    test = df_pred

    y_train = train[["Solar"]]
    x_train = train[["Sun", "Mean_tmp"]]

    # y_test = test[["Solar"]]
    x_test = test[["Sun", "Mean_tmp"]]

    best_model = auto_arima(y=y_train, X=x_train, trace=True)

    predictions = best_model.predict(n_periods=len(x_test), X=x_test)
    preds = pd.DataFrame(predictions, index=x_test.index, columns=[x_test.columns[0] + '_pred'])

    # predictions_plt = pd.concat([y_train, preds])
    # true_values_plt = pd.concat([y_train, y_test])

    pyplot.plot(y_train, label='Predicted')
    pyplot.plot(predictions, label='Actual')
    pyplot.legend()
    pyplot.show()

    return predictions


def sarimax_wind(df_hist, df_pred):
    # Split to train test
    train = df_hist
    test = df_pred

    y_train = train[["Eólica"]]
    x_train = train[["Wind"]]

    # y_test = test[["Solar"]]
    x_test = test[["Wind"]]

    best_model = auto_arima(y=y_train, X=x_train, trace=True)

    predictions = best_model.predict(n_periods=len(x_test), X=x_test)
    preds = pd.DataFrame(predictions, index=x_test.index, columns=[x_test.columns[0] + '_pred'])

    # predictions_plt = pd.concat([y_train, preds])
    # true_values_plt = pd.concat([y_train, y_test])

    pyplot.plot(y_train, label='Predicted')
    pyplot.plot(predictions, label='Actual')
    pyplot.legend()
    pyplot.show()

    return predictions


if __name__ == '__main__':
    df = pd.read_pickle("data/all_historic_data.pkl")
    df = df.dropna(axis=0)

    df2 = pd.read_pickle("data/all_predictions.pkl")
    preds_solar = sarimax_solar(df, df2)
    preds_wind = sarimax_wind(df, df2)
    print(preds_wind, preds_solar)

    df2_ret = pd.concat([preds_solar, preds_wind], axis=1)
    df2_ret = df2_ret.reset_index()

    df2_ret.to_json("data/prediction.json", date_format='iso', orient='split')


def xgboost():
    df = pd.read_pickle("data/all_historic_data.pkl")
    df = df.dropna(axis=0)

    # Split to train test
    train = df.iloc[:-30]
    test = df.iloc[-30:]

    y_train = train[["Solar"]]
    x_train = train[["Sun", "Mean_tmp"]]

    y_test = test[["Solar"]]
    x_test = test[["Sun", "Mean_tmp"]]

    model = XGBClassifier()
    model.fit(x_train, y_train)
    # make predictions for test data
    y_pred = model.predict(x_test)
    predictions = [round(value) for value in y_pred]

    predictions_plt = pd.concat([y_train, preds])
    true_values_plt = pd.concat([y_train, y_test])

    pyplot.plot(predictions_plt, label='Predicted')
    pyplot.plot(true_values_plt, label='Actual')
    pyplot.legend()
    pyplot.show()
