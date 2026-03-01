import 'dart:async';

/// Interface for cloud storage providers (e.g., Firebase, Supabase).
abstract class CloudSyncProvider {
  /// Unique identifier for the user/device in the cloud.
  Future<String?> get userId;

  /// Upload data to the cloud for a specific key.
  Future<void> upload(String key, String data, int timestamp);

  /// Download data from the cloud for a specific key.
  Future<CloudData?> download(String key);

  /// Synchronize all keys in one batch (optional optimization).
  Future<void> syncAll(Map<String, CloudData> data);
}

/// Represents data stored in the cloud with a timestamp for conflict resolution.
class CloudData {
  final String data;
  final int timestamp;

  CloudData(this.data, this.timestamp);

  Map<String, dynamic> toJson() => {
        'd': data,
        't': timestamp,
      };

  factory CloudData.fromJson(Map<String, dynamic> json) {
    return CloudData(
      json['d'] as String,
      json['t'] as int,
    );
  }
}

/// Service that orchestrates synchronization between local storage and cloud.
class CloudSyncService {
  final CloudSyncProvider provider;
  
  CloudSyncService(this.provider);

  /// Synchronizes a specific key with the cloud.
  /// 
  /// Uses a Last-Write-Wins (LWW) strategy based on timestamps.
  /// Returns the latest data (either local or cloud).
  Future<String?> syncKey(String key, String localData, int localTimestamp) async {
    try {
      final cloud = await provider.download(key);
      
      if (cloud == null) {
        // No cloud data, upload local
        await provider.upload(key, localData, localTimestamp);
        return localData;
      }

      if (localTimestamp > cloud.timestamp) {
        // Local is newer, upload to cloud
        await provider.upload(key, localData, localTimestamp);
        return localData;
      } else if (cloud.timestamp > localTimestamp) {
        // Cloud is newer, return cloud data to be saved locally
        return cloud.data;
      }

      // Timestamps are equal, no sync needed
      return localData;
    } catch (e) {
      // In case of error (e.g. offline), return local data
      return localData;
    }
  }

  /// Background sync of all tracked keys.
  Future<void> backgroundSync(Map<String, ({String data, int timestamp})> localMap) async {
    for (final entry in localMap.entries) {
      await syncKey(entry.key, entry.value.data, entry.value.timestamp);
    }
  }
}
