import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.evaclinical.rotations',
  appName: 'Eva Clinical Rotations',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  }
};

export default config;
