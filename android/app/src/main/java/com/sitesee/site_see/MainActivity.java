package com.sitesee.site_see;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;

import androidx.core.content.FileProvider;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.sitesee.site_see/camera";
    private static final int REQUEST_CAMERA  = 1001;
    private static final int REQUEST_GALLERY = 1002;

    private MethodChannel.Result pendingResult;
    private File photoFile;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (pendingResult != null) {
                        result.error("IN_PROGRESS", "Une autre action caméra est déjà en cours.", null);
                        return;
                    }
                    pendingResult = result;

                    switch (call.method) {
                        case "takePhoto":
                            launchCamera();
                            break;
                        case "pickGallery":
                            launchGallery();
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }

    // Lance la caméra Android native via ACTION_IMAGE_CAPTURE
    private void launchCamera() {
        try {
            photoFile = createImageFile();

            Uri photoUri = FileProvider.getUriForFile(
                    this,
                    getPackageName() + ".fileprovider",
                    photoFile
            );

            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            intent.putExtra(MediaStore.EXTRA_OUTPUT, photoUri);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION);

            if (intent.resolveActivity(getPackageManager()) == null) {
                if (pendingResult != null) {
                    pendingResult.error("NO_CAMERA_APP", "Aucune application caméra disponible.", null);
                    pendingResult = null;
                }
                return;
            }
            startActivityForResult(intent, REQUEST_CAMERA);

        } catch (Exception e) {
            if (pendingResult != null) {
                pendingResult.error("CAMERA_ERROR", e.getMessage(), null);
                pendingResult = null;
            }
        }
    }

    // Lance la galerie Android native via ACTION_PICK
    private void launchGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        startActivityForResult(intent, REQUEST_GALLERY);
    }

    // Crée un fichier temporaire unique dans le dossier Pictures
    private File createImageFile() throws Exception {
        String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(new Date());
        File storageDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        if (storageDir == null) {
            throw new Exception("Impossible d'accéder au dossier Pictures.");
        }
        return File.createTempFile("IMG_" + timestamp + "_", ".jpg", storageDir);
    }

    // Reçoit le résultat de la caméra ou de la galerie
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (pendingResult == null) return;

        if (resultCode != Activity.RESULT_OK) {
            // L'utilisateur a annulé
            pendingResult.success(null);
            pendingResult = null;
            return;
        }

        if (requestCode == REQUEST_CAMERA) {
            // La photo est dans photoFile
            pendingResult.success(photoFile != null ? photoFile.getAbsolutePath() : null);

        } else if (requestCode == REQUEST_GALLERY) {
            // Convertit le content:// URI en chemin absolu
            Uri uri = data.getData();
            pendingResult.success(getRealPathFromUri(uri));
        }

        pendingResult = null;
        photoFile = null;
    }

    // Convertit un content:// URI en chemin absolu lisible par Flutter
    private String getRealPathFromUri(Uri uri) {
        if (uri == null) return null;

        String[] projection = { MediaStore.Images.Media.DATA };
        android.database.Cursor cursor = getContentResolver().query(uri, projection, null, null, null);

        if (cursor == null) return null;

        try {
            int columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
            cursor.moveToFirst();
            return cursor.getString(columnIndex);
        } finally {
            cursor.close();
        }
    }
}