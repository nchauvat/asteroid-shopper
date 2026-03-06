/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/eLtMosen>
 *               2025 - Ed Beroset <beroset@ieee.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef FILEHELPER_H
#define FILEHELPER_H
#include <QObject>
#include <QJSEngine>
#include <QQmlEngine>

class FileHelper : public QObject
{
    Q_OBJECT
    Q_DISABLE_COPY(FileHelper)
    FileHelper() {}
public:
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine)
    {
        Q_UNUSED(engine);
        Q_UNUSED(scriptEngine);
        return new FileHelper;
    }
    Q_INVOKABLE bool exists(const QString &listName);
    Q_INVOKABLE QString readFile(const QString &listName);
    Q_INVOKABLE bool writeFile(const QString &listName, const QString &content);
private:
    static QString listPath(const QString &listName);
};
#endif // FILEHELPER_H
