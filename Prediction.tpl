___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Prediction",
  "description": "Made by Ramon",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "events",
    "displayName": "Eventliste",
    "simpleValueType": true,
    "help": "Eventliste, bei der Anfrage an API ausgeführt werden soll."
  },
  {
    "type": "TEXT",
    "name": "projectNumber",
    "displayName": "Google Cloud Project Number hosting the Vertex AI model",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "cloudLocation",
    "displayName": "Cloud region where the Vertex AI model is deployed",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "vertexEndpointID",
    "displayName": "ID of the Vertex Endpoint to use",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "requestData",
    "displayName": "Request Data",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "SIMPLE_TABLE",
        "name": "data",
        "displayName": "",
        "simpleTableColumns": [
          {
            "defaultValue": "",
            "displayName": "Property",
            "name": "key",
            "type": "TEXT"
          },
          {
            "defaultValue": "",
            "displayName": "Value",
            "name": "value",
            "type": "TEXT"
          }
        ],
        "newRowButtonText": "Add Value"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "defaultValueOnError",
    "displayName": "The value that should be returned if an error occurs",
    "simpleValueType": true,
    "defaultValue": 0
  },
  {
    "type": "CHECKBOX",
    "name": "multiply_with_value",
    "checkboxText": "Multiply return value with e.g. transaction value",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "multiplier",
    "displayName": "Multiplier",
    "simpleValueType": true,
    "enablingConditions": [
      {
        "paramName": "multiply_with_value",
        "paramValue": true,
        "type": "EQUALS"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const getEventData = require("getEventData");
const getGoogleAuth = require("getGoogleAuth");
const JSON = require("JSON");
const logToConsole = require("logToConsole");
const makeInteger = require("makeInteger");
const makeNumber = require("makeNumber");
const makeString = require("makeString");
const makeTableMap = require("makeTableMap");
const sendHttpRequest = require("sendHttpRequest");
const event_list = data.events;
const event = getEventData("event_name");

// Build the URL for Vertex AI.
const url = "https://" + data.cloudLocation +
  "-aiplatform.googleapis.com/v1/projects/" + data.projectNumber +
  "/locations/" + data.cloudLocation + "/endpoints/" + data.vertexEndpointID +
  ":predict";
logToConsole(url);

// Get Google credentials from the service account running the container.
const auth = getGoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"]
});

// Helper function for determining if the string starts with a suffix.
const strEndsWith = (str, suffix) => {
  return str.indexOf(suffix, str.length - suffix.length) !== -1;
};

// Build an object containing all the global default values configured in the
// variable.
let globalValues = {};
if (data.data) {
  let customData = makeTableMap(data.data, 'key', 'value');
  for (let key in customData) {
    key = makeString(key);
    if (strEndsWith(key, '_int')) {
      const new_key = key.replace('_int', '');
      globalValues[new_key] = makeInteger(customData[key]);
    } else if (strEndsWith(key, '_num')) {
      const new_key = key.replace('_num', '');
      globalValues[new_key] = makeNumber(customData[key]);
    } else {
      globalValues[key] = customData[key];
    }
  }
}

// Iterate over the items in the datalayer to build up prediction data, and add
// global values where they are missing.
// globalValues.day = makeNumber(globalValues.day);
let predictionData = [globalValues];

// The payload for VertexAI.
const postBodyData = {
  "instances": predictionData,
  "parameters": {}
};
const postBody = JSON.stringify(postBodyData);

const postHeaders = {
  "Content-Type": "application/json"
};
const requestOptions = {
  headers: postHeaders,
  method: "POST",
  authorization: auth
};

// Make the request to Vertex AI & process the response.
if (event_list.split(',').indexOf(event) > -1) {
  return sendHttpRequest(url, requestOptions, postBody)
    .then(success_result => {
      logToConsole(JSON.stringify(success_result));
      if (success_result.statusCode >= 200 && success_result.statusCode < 300) {
        let result_object = JSON.parse(success_result.body);
        let value = result_object.predictions[0].converted_sale_probs[0];
        if (data.multiply_with_value && data.multiplier) {
          value = value * data.multiplier;
        }
        return value;
      } else {
        return data.defaultValueOnError;
      }
    })
    .catch((error) => {
      logToConsole("Error with VertexAI call to " + url + ". Error: ", error);
      return data.defaultValueOnError;
    }
  );
} else {
  logToConsole("No Vertex AI API query for this event.");
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "use_google_credentials",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedScopes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://www.googleapis.com/auth/cloud-platform"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Simple test case to show Vertex AI behaves as expected
  code: |
    const mockVariableData = {
      projectNumber: "11111111111",
      vertexEndpointId: "1234567891011121314",
      cloudLocation: "europe-west2"
    };

    generateMockData([
      {"item_id": "shoes", "item_name": "Shoes", "revenue": 80, "quantity": 2, "prediction": 1},
      {"item_id": "tshirt", "item_name": "T-Shirt", "revenue": 30, "quantity": 1, "prediction": 1},
    ], 200);

    runCode(mockVariableData).then((resp) => {
      assertThat(resp).isString();
      assertThat(resp).isEqualTo("2");
    });
- name: Check default returned on error status code
  code: |
    const mockVariableData = {
      projectNumber: "11111111111",
      vertexEndpointId: "1234567891011121314",
      cloudLocation: "europe-west2",
      defaultValueOnError: "0",
    };

    generateMockData([
      {"item_id": "shoes", "item_name": "Shoes", "revenue": 80, "quantity": 2, "prediction": 1},
    ], 500);

    runCode(mockVariableData).then((resp) => {
      assertThat(resp).isString();
      assertThat(resp).isEqualTo("0");
    });
setup: |-
  const Promise = require("Promise");

  const purchasedProducts = [];
  let vertexAIResonse;

  /**
   * Build the mock data from the items.
   * This method changes the global purchasedProducts & vertexAIResonse variables,
   * which are then used in the mock logic.
   * @param {!Array<number>} items - the items to mock.
   * @param {number} statusCode - the status code to use in the VertexAI response.
   */
  function generateMockData(items, statusCode) {
    generateMockItems(items);
    generateMockVertexAI(items, statusCode);
  }

  /**
   * Build the mock items from the event.
   * This method changes the global purchasedProducts variable, which is used in
   * the mock logic.
   * @param {!Array<number>} items - the items to mock.
   */
  function generateMockItems(items) {
    for (const item of items) {
      purchasedProducts.push({
        "item_id": item.item_id,
        "item_name": item.item_name,
        "price": item.revenue,
        "quantity": item.quantity
      });
    }
  }

  /**
   * Build the mock response from VertexAI.
   * This method changes the global vertexAIResonse variable, which is used in
   * the mock logic.
   * @param {!Array<number>} items - the items to mock.
   * @param {number} statusCode - the status code to use in the VertexAI response.
   */
  function generateMockVertexAI(items, statusCode) {
    let predictions = [];
    for (const item of items){
      predictions.push(item.prediction);
    }
    const predictionString = predictions.join(', ');
    vertexAIResonse = {
      "statusCode": statusCode,
      "body":"{\"predictions\": [" + predictionString + "]}"
    };
  }

  // Change sendHttpRequest to return our mocked VertexAI response.
  mock("sendHttpRequest", () => {
    return Promise.create((resolve) => {
      resolve(vertexAIResonse);
    });
  });

  // Inject our products into the event data.
  mock("getEventData", (data) => {
    if (data === "items") {
      return purchasedProducts;
    }
  });


___NOTES___

Created on 5/3/2023, 5:16:28 PM


