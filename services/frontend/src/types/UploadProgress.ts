export interface UploadProgress {
  status: 'uploading' | 'processing';
  filename: string;
  id?: string;
  processed?: number;
  total?: number;
}


