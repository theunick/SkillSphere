console.log('google_picker.js loaded');

let tokenClient;
let accessToken = null;
let pickerInited = false;
let gisInited = false;

// Use the API Loader script to load google.picker
function onApiLoad() {
  console.log('API Loader script loaded');
  gapi.load('picker', onPickerApiLoad);
}

function onPickerApiLoad() {
  pickerInited = true;
  console.log('Google Picker API loaded');
  maybeEnablePickerButton();
}

function gisLoaded() {
  console.log('GIS loaded function called');
  tokenClient = google.accounts.oauth2.initTokenClient({
    client_id: googleClientId,
    scope: 'https://www.googleapis.com/auth/drive.readonly',
    callback: '', // defined later
  });
  gisInited = true;
  console.log('GIS loaded');
  maybeEnablePickerButton();
}

function maybeEnablePickerButton() {
  console.log('Checking if GIS and Picker are loaded');
  console.log(`gisInited: ${gisInited}, pickerInited: ${pickerInited}`);
  if (gisInited && pickerInited) {
    const pickerButton = document.getElementById('google-picker-btn');
    if (pickerButton) {
      pickerButton.disabled = false;
      console.log('Google Picker button enabled');
    } else {
      console.log('Google Picker button not found');
    }
  } else {
    console.log('GIS or Picker not yet loaded');
  }
}

function createPicker() {
  console.log('Creating Picker');
  const showPicker = () => {
    const picker = new google.picker.PickerBuilder()
        .addView(google.picker.ViewId.DOCS)
        .setOAuthToken(accessToken)
        .setDeveloperKey(googleApiKey)
        .setCallback(pickerCallback)
        .enableFeature(google.picker.Feature.MULTISELECT_ENABLED)  // Abilita la selezione multipla
        .build();
    picker.setVisible(true);
  }

  tokenClient.callback = async (response) => {
    if (response.error !== undefined) {
      throw (response);
    }
    accessToken = response.access_token;
    showPicker();
  };

  if (accessToken === null) {
    tokenClient.requestAccessToken({prompt: 'consent'});
  } else {
    tokenClient.requestAccessToken({prompt: ''});
  }
}

function pickerCallback(data) {
  if (data[google.picker.Response.ACTION] == google.picker.Action.PICKED) {
    const files = data[google.picker.Response.DOCUMENTS];
    const resultContainer = document.getElementById('result');
    const fileIds = files.map(file => file.id);

    resultContainer.innerHTML = ''; // Clear previous results

    files.forEach(file => {
      const fileId = file.id;
      const fileName = file.name;
      const fileUrl = file.url;

      const fileElement = document.createElement('div');
      fileElement.innerHTML = `
        <p><strong>File Name:</strong> ${fileName}</p>
        <p><strong>File URL:</strong> <a href="${fileUrl}" target="_blank">${fileUrl}</a></p>
        <button onclick="fetchFileDetails('${fileId}')">Get File Details</button>
        <div id="file-details-${fileId}"></div>
      `;

      resultContainer.appendChild(fileElement);
    });

    // Save the selected file IDs in the hidden field
    document.getElementById('google-drive-file-ids').value = JSON.stringify(fileIds);
  }
}

function fetchFileDetails(fileId) {
  gapi.client.drive.files.get({
    fileId: fileId,
    fields: 'id, name, mimeType, webViewLink, webContentLink'
  }).then(function(response) {
    const file = response.result;
    const fileDetailsContainer = document.getElementById(`file-details-${fileId}`);

    fileDetailsContainer.innerHTML = `
      <p><strong>File ID:</strong> ${file.id}</p>
      <p><strong>File Name:</strong> ${file.name}</p>
      <p><strong>File MIME Type:</strong> ${file.mimeType}</p>
      <p><strong>File View Link:</strong> <a href="${file.webViewLink}" target="_blank">${file.webViewLink}</a></p>
      <p><strong>File Download Link:</strong> <a href="${file.webContentLink}" target="_blank">${file.webContentLink}</a></p>
    `;
  });
}

document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM fully loaded and parsed');
  const pickerButton = document.getElementById('google-picker-btn');
  if (pickerButton) {
    pickerButton.addEventListener('click', function() {
      console.log('Google Picker button clicked');
      createPicker();
    });
    pickerButton.disabled = true; // Disable the button until APIs are loaded
    console.log('Google Picker button found and disabled');
  } else {
    console.log('Google Picker button not found');
  }
});

document.addEventListener('DOMContentLoaded', function() {
  const reportedCoursesLink = document.getElementById('reported-courses-link');
  if (reportedCoursesLink) {
    console.log('Reported Courses Link:', reportedCoursesLink.href);
    reportedCoursesLink.addEventListener('click', function() {
      console.log('Reported Courses Link clicked');
    });
  }
});

