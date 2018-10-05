/*
Copyright (c) 2015 Pablo GM <invanzert@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import Foundation

@objc class FileManagerSaif: NSObject {

    class func getPath(name: String, ext: String) -> NSURL{
        
       
        
        let urlPath  =  NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name + "." + ext)
        let tempPath = urlPath!.absoluteString
        
        if FileManager.default.fileExists(atPath: (urlPath?.path)!) {
            do {
                try FileManager.default.removeItem(at: urlPath!)
            }
            catch let error as NSError {
                
                print("Failed to remove item \(tempPath), error = \(error)")
            }
        }
        
        return NSURL(string: tempPath)!
    }
    
    class func contentsOfDirectory() {
        
        let documentsUrl =  NSURL(fileURLWithPath: NSTemporaryDirectory())
        
        // Now lets get the directory contents (including folders)
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            
            for url: URL in directoryContents {
                
                print(url.absoluteString)
                
                // Remove contents of directory (element by element)
                do {
                    try FileManager.default.removeItem(at: url)
                    
                }
                catch let error as NSError {
                    print("Could not remove existing firmware file: \(url): error: \(error.description)")
                }
            }
            
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    class func getVideoName(url: String) -> String {
        
        return NSURL(string: url)?.lastPathComponent ?? ""
    }
    
    class func getVidePath(name: String, ext: String) -> URL {
        
        let fileManager     = FileManager.default
        let directoryURL    = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pathComponent   = getVideoName(url: name)
        let fileURL         = directoryURL.appendingPathComponent(pathComponent).appendingPathExtension(ext)
        
        return fileURL
    }
}
