//
//  ContentView.swift
//  kandji-demo
//
//  Created by Zachary Gorak on 9/23/21.
//

import SwiftUI
import ApplicationServices

struct SidebarView: View {
    @Binding var folder: String
    @Binding var files: [FileItem]
    
    var body: some View {
        List {
            HStack(alignment: .center) {
                Text("Folder").font(.headline).foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    self.reload()
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
            }
            DisclosureGroup(content: {
                HStack {
                    Text("Files")
                    Spacer()
                    Text("\(self.files.count)")
                }
                HStack {
                    Text("Safe")
                    Spacer()
                    Text("\(self.files.filter({$0.isSafe}).count)")
                }
                
            }, label: {
                TextField(FileManager.default.homeDirectoryForCurrentUser.absoluteString, text: $folder)
            })
            
        }.listStyle(SidebarListStyle())
    }
    
    
    private func reload() {
        
    }
}

struct FileItem: CodablEquatable, Identifiable {
    var id: String {
        return self.path + self.cmd
    }
    
    var path: String
    var cmd: String
    
    var isSafe: Bool {
        if cmd.contains("image") {
            return true
        }
        
        return false
    }
}

class FileObserver: ObservableObject {
    var path: String? = nil
    var xpcProtocol: XpcProtocol? = nil
    
    @Published var files = [FileItem]()
    
    @Published var error: Error? = nil
    
    static var connection: NSXPCConnection = {
        let connection = NSXPCConnection(serviceName: "com.twodayslate.kandji-demo.filexpc")
        connection.remoteObjectInterface = NSXPCInterface(with: XpcProtocol.self)
        connection.resume()
        
        return connection
    }()
    
    init() {
        self.xpcProtocol = (FileObserver.connection.synchronousRemoteObjectProxyWithErrorHandler({
            error in
            print(error)
        }) as? XpcProtocol)
    }
    
    func update(path: String) {
        self.path = path
        
        self.error = nil
        self.files.removeAll()
        
        guard let path = self.path else {
            return
        }
        
        
        do {
            let directory = try FileManager.default.contentsOfDirectory(atPath: path)
            
            for file in directory {
                let full_path = URL(fileURLWithPath: file, relativeTo: URL(string: "file://" + path)).path
                self.xpcProtocol?.uppercase(full_path) { ans in
                    self.files.append(FileItem(path: full_path, cmd: ans))
                }
            }
        } catch {
            self.error = error
        }
        
        
    }
}

struct ContentView: View {
    @AppStorage("path") var path: String = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].path

    @StateObject var fileObserver = FileObserver()
    
    var body: some View {
        NavigationView {
            SidebarView(folder: $path, files: self.$fileObserver.files)
            if let err = self.fileObserver.error {
                Text("\(err.localizedDescription)")
            } else {
                List {
                    ForEach(self.fileObserver.files) { file in
                        HStack {
                            if file.isSafe {
                                Text("\(file.path)").foregroundColor(.green)
                            } else {
                                Text("\(file.cmd)").foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }.toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: { // 1
                    Image(systemName: "sidebar.leading")
                })
            }
        }
        .onAppear {
            self.fileObserver.update(path: self.path)
        }
        .onChange(of: self.path) { val in
            self.fileObserver.update(path: val)
        }
    }
    
    /// https://sarunw.com/posts/how-to-toggle-sidebar-in-macos/
    private func toggleSidebar() {
            #if os(iOS)
            #else
            NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
            #endif
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
