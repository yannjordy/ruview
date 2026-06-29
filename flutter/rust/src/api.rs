use std::sync::Arc;
use wifi_densepose_core::types::CsiFrame;
use wifi_densepose_core::error::Result;

/// Calibrate a room: returns baseline CSI profile.
pub fn calibrate_room(room_id: String, duration_secs: u32) -> Result<String> {
    #[cfg(feature = "wifi_densepose_calibration")]
    {
        wifi_densepose_calibration::calibrate(&room_id, duration_secs)
            .map(|_| format!("Room '{}' calibrated ({}s)", room_id, duration_secs))
    }
    #[cfg(not(feature = "wifi_densepose_calibration"))]
    {
        let _ = (room_id, duration_secs);
        Ok(format!("Mock calibration complete ({duration_secs}s)"))
    }
}

/// Extract vitals from a CSI frame.
pub fn extract_vitals(frame_json: String) -> Result<VitalsOutput> {
    let frame: CsiFrame = serde_json::from_str(&frame_json)
        .map_err(|e| wifi_densepose_core::error::AetherisError::ParseError(e.to_string()))?;

    #[cfg(feature = "wifi_densepose_vitals")]
    {
        let br = wifi_densepose_vitals::extract_breathing(&frame);
        let hr = wifi_densepose_vitals::extract_heart_rate(&frame);
        Ok(VitalsOutput {
            breathing_rate: br.bpm,
            br_confidence: br.confidence,
            heart_rate: hr.bpm as u32,
            hr_confidence: hr.confidence,
        })
    }
    #[cfg(not(feature = "wifi_densepose_vitals"))]
    {
        let _ = frame;
        Ok(VitalsOutput {
            breathing_rate: 16.0,
            br_confidence: 0.85,
            heart_rate: 72,
            hr_confidence: 0.80,
        })
    }
}

pub fn detect_presence(frame_json: String) -> Result<PresenceOutput> {
    let frame: CsiFrame = serde_json::from_str(&frame_json)
        .map_err(|e| wifi_densepose_core::error::AetherisError::ParseError(e.to_string()))?;

    let phase_variance = wifi_densepose_signal::phase_variance(&frame);
    let present = phase_variance > 0.02;

    Ok(PresenceOutput {
        present,
        confidence: if present { phase_variance * 10.0 } else { 1.0 - phase_variance * 10.0 }
            .clamp(0.0, 1.0),
        phase_variance,
    })
}

pub fn process_csi(subcarriers: Vec<Vec<f64>>) -> ProcessedCsi {
    let smoothed = wifi_densepose_signal::hampel_filter_2d(&subcarriers, 5, 3.0);
    let mean_amp: f64 = smoothed.iter()
        .flat_map(|s| s.iter())
        .copied()
        .sum::<f64>()
        / (smoothed.len() * smoothed.first().map(|s| s.len()).unwrap_or(1)) as f64;

    ProcessedCsi {
        smoothed,
        mean_amplitude: mean_amp,
        subcarrier_count: subcarriers.first().map(|s| s.len()).unwrap_or(0) as u32,
        antenna_count: subcarriers.len() as u32,
    }
}

// ---- Output types ----

pub struct VitalsOutput {
    pub breathing_rate: f64,
    pub br_confidence: f64,
    pub heart_rate: u32,
    pub hr_confidence: f64,
}

pub struct PresenceOutput {
    pub present: bool,
    pub confidence: f64,
    pub phase_variance: f64,
}

pub struct ProcessedCsi {
    pub smoothed: Vec<Vec<f64>>,
    pub mean_amplitude: f64,
    pub subcarrier_count: u32,
    pub antenna_count: u32,
}
