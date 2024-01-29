import UIKit

final class Todo: Codable {
    var content: String
    var isDone: Bool
    
    init(content: String, isDone: Bool) {
        self.content = content
        self.isDone = isDone
    }
}

final class Presenter {
    private var todos = [
        Todo(content: "집안 일", isDone: false),
        Todo(content: "공부하기", isDone: false),
        Todo(content: "TIL 쓰기", isDone: false)
    ]
    
    var count: Int {
        todos.count
    }
    
    func append(content: String) {
        todos.append(Todo(content: content, isDone: false))
    }
    
    func fetch() {
        guard let data = UserDefaults.standard.data(forKey: "todos") else { return }
        do {
            let decodedData = try JSONDecoder().decode([Todo].self, from: data)
            todos = decodedData
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func save() {
        do {
            let encoded = try JSONEncoder().encode(todos)
            UserDefaults.standard.set(encoded, forKey: "todos")
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func get(at: Int) -> String {
        todos[at].content
    }
    
    func remove(at: Int) {
        todos.remove(at: at)
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    // MARK: Dependency
    let presenter = Presenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "할 일 추가", message: nil, preferredStyle: .alert)
        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            if let textField = alertController.textFields?.first,
               let text = textField.text, text.isEmpty == false {
                guard let self = self else { return }
                self.presenter.append(content: text)
                self.tableview.performBatchUpdates {
                    self.tableview.insertRows(at: [IndexPath(row: self.presenter.count-1, section: 0)], with: .automatic)
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.placeholder = "할 일을 입력해주세요."
        }
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func fetchButtonTapped(_ sender: Any) {
        indicator.startAnimating()
        Task { @MainActor in
            presenter.fetch()
            self.tableview.reloadData()
            self.indicator.stopAnimating()
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        indicator.startAnimating()
        Task { @MainActor in
            presenter.save()
            self.indicator.stopAnimating()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = presenter.get(at: indexPath.row)
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.imageView?.image = cell?.imageView?.image == nil ? UIImage(systemName: "checkmark") : nil
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            presenter.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

